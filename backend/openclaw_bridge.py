"""
openclaw_bridge.py - Integration Bridge for OpenClaw Gateway

This module provides integration between GDI backend and OpenClaw Gateway,
allowing voice commands to trigger system actions through the AI assistant.

OpenClaw Gateway WebSocket API:
- Default: ws://127.0.0.1:18789
- Authentication: Token-based or password
"""

import asyncio
import json
import logging
from typing import Optional, Callable, Dict, Any
import websockets
from websockets.client import WebSocketClientProtocol

logger = logging.getLogger(__name__)


class OpenClawBridge:
    """Bridge to communicate with OpenClaw Gateway for voice command integration."""
    
    def __init__(
        self,
        gateway_url: str = "ws://127.0.0.1:18789",
        auth_token: Optional[str] = None,
        session_id: str = "main"
    ):
        """
        Initialize OpenClaw Gateway bridge.
        
        Args:
            gateway_url: WebSocket URL of OpenClaw Gateway
            auth_token: Authentication token (if required)
            session_id: Session ID for message routing (default: "main")
        """
        self.gateway_url = gateway_url
        self.auth_token = auth_token
        self.session_id = session_id
        self.ws: Optional[WebSocketClientProtocol] = None
        self.connected = False
        self.message_handlers: Dict[str, Callable] = {}
        self._running = False
        
    async def connect(self) -> bool:
        """
        Connect to OpenClaw Gateway.
        
        Returns:
            True if connection successful, False otherwise
        """
        try:
            # Build additional headers if needed
            additional_headers = []
            if self.auth_token:
                additional_headers.append(("Authorization", f"Bearer {self.auth_token}"))
            
            self.ws = await websockets.connect(
                self.gateway_url,
                additional_headers=additional_headers if additional_headers else None,
                ping_interval=20,
                ping_timeout=10
            )
            self.connected = True
            logger.info(f"Connected to OpenClaw Gateway at {self.gateway_url}")
            
            # Start listening for messages
            asyncio.create_task(self._listen())
            
            return True
            
        except Exception as e:
            logger.error(f"Failed to connect to OpenClaw Gateway: {e}")
            self.connected = False
            return False
    
    async def disconnect(self):
        """Disconnect from OpenClaw Gateway."""
        self._running = False
        if self.ws:
            await self.ws.close()
            self.connected = False
            logger.info("Disconnected from OpenClaw Gateway")
    
    async def _listen(self):
        """Listen for messages from OpenClaw Gateway."""
        self._running = True
        
        try:
            while self._running and self.ws:
                try:
                    message = await self.ws.recv()
                    await self._handle_message(message)
                except websockets.exceptions.ConnectionClosed:
                    logger.warning("OpenClaw Gateway connection closed")
                    self.connected = False
                    break
                except Exception as e:
                    logger.error(f"Error receiving message: {e}")
                    
        except Exception as e:
            logger.error(f"Error in listen loop: {e}")
            self.connected = False
    
    async def _handle_message(self, message: str):
        """
        Handle incoming messages from OpenClaw Gateway.
        
        Args:
            message: JSON message from gateway
        """
        try:
            data = json.loads(message)
            msg_type = data.get("type", "")
            
            # Route to registered handlers
            if msg_type in self.message_handlers:
                await self.message_handlers[msg_type](data)
            else:
                logger.debug(f"Unhandled message type: {msg_type}")
                
        except json.JSONDecodeError:
            logger.error(f"Invalid JSON from gateway: {message}")
        except Exception as e:
            logger.error(f"Error handling message: {e}")
    
    def on_message(self, msg_type: str):
        """
        Decorator to register message handlers.
        
        Usage:
            @bridge.on_message("agent.response")
            async def handle_response(data):
                print(data)
        """
        def decorator(func: Callable):
            self.message_handlers[msg_type] = func
            return func
        return decorator
    
    async def send_message(self, session_id: str, message: str) -> bool:
        """
        Send a message to OpenClaw agent.
        
        Args:
            session_id: Target session ID (e.g., "main")
            message: Message to send to the agent
            
        Returns:
            True if sent successfully
        """
        if not self.connected or not self.ws:
            logger.error("Not connected to OpenClaw Gateway")
            return False
        
        try:
            payload = {
                "type": "message.send",
                "sessionId": session_id,
                "message": message,
                "timestamp": asyncio.get_event_loop().time()
            }
            
            await self.ws.send(json.dumps(payload))
            logger.info(f"Sent message to session '{session_id}': {message}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to send message: {e}")
            return False
    
    async def execute_command(self, command: str) -> Dict[str, Any]:
        """
        Execute a system command through OpenClaw's agent.
        
        Args:
            command: Natural language command (e.g., "create a website for me")
            
        Returns:
            Response from the agent
        """
        # Reconnect if connection was lost
        if not self.connected or not self.ws:
            logger.info("Reconnecting to OpenClaw Gateway...")
            await self.connect()
        
        if not self.connected:
            return {"error": "Not connected to OpenClaw Gateway"}
        
        try:
            # Create a future to wait for the response
            response_future = asyncio.Future()
            
            # Register temporary handler for this command
            request_id = f"cmd_{asyncio.get_event_loop().time()}"
            
            async def handle_response(data):
                if data.get("requestId") == request_id:
                    response_future.set_result(data)
            
            self.message_handlers[f"response_{request_id}"] = handle_response
            
            # Send command
            payload = {
                "type": "agent.execute",
                "requestId": request_id,
                "sessionId": self.session_id,
                "command": command,
                "timestamp": asyncio.get_event_loop().time()
            }
            
            await self.ws.send(json.dumps(payload))
            logger.info(f"Sent command to OpenClaw: {command}")
            
            # Wait for response with timeout
            try:
                response = await asyncio.wait_for(response_future, timeout=30.0)
                return response
            except asyncio.TimeoutError:
                logger.warning(f"Command timeout, attempting to reconnect...")
                # Connection might be dead, mark as disconnected
                self.connected = False
                return {"error": "Command execution timeout"}
            
        except Exception as e:
            logger.error(f"Failed to execute command: {e}")
            self.connected = False  # Mark as disconnected to trigger reconnect
            return {"error": str(e)}
    
    async def get_session_status(self, session_id: str = "main") -> Dict[str, Any]:
        """
        Get status of an OpenClaw session.
        
        Args:
            session_id: Session ID to query
            
        Returns:
            Session status information
        """
        if not self.connected or not self.ws:
            return {"error": "Not connected"}
        
        try:
            payload = {
                "type": "sessions.status",
                "sessionId": session_id
            }
            
            await self.ws.send(json.dumps(payload))
            
            # In a real implementation, you'd wait for the response
            return {"status": "request_sent"}
            
        except Exception as e:
            logger.error(f"Failed to get session status: {e}")
            return {"error": str(e)}


# Standalone function to check if OpenClaw is running
async def is_openclaw_running(gateway_url: str = "ws://127.0.0.1:18789") -> bool:
    """
    Check if OpenClaw Gateway is accessible.
    
    Args:
        gateway_url: WebSocket URL to check
        
    Returns:
        True if gateway is running and accessible
    """
    try:
        async with websockets.connect(gateway_url, ping_interval=None) as ws:
            await ws.close()
            return True
    except Exception:
        return False


# Example usage
async def main():
    """Example usage of OpenClawBridge."""
    bridge = OpenClawBridge()
    
    # Register a handler for agent responses
    @bridge.on_message("agent.response")
    async def handle_response(data):
        logger.info(f"Agent response: {data}")
    
    # Connect to gateway
    if await bridge.connect():
        # Send a test message
        await bridge.send_message("main", "Hello OpenClaw!")
        
        # Execute a command
        result = await bridge.execute_command("create a simple HTML page")
        logger.info(f"Command result: {result}")
        
        # Keep running for a bit
        await asyncio.sleep(5)
        
        # Disconnect
        await bridge.disconnect()
    else:
        logger.error("Failed to connect to OpenClaw Gateway")


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    asyncio.run(main())
