#!/usr/bin/env python3
"""
Demo: Voice Commands with OpenClaw Integration

This script demonstrates the voice command capabilities of GDI with OpenClaw.
It simulates voice commands without actually using speech recognition.

Run this to see how commands are processed and executed.
"""

import asyncio
import sys
from pathlib import Path

# Add backend to path
sys.path.insert(0, str(Path(__file__).parent / "backend"))

from openclaw_bridge import OpenClawBridge
from voice_commands import VoiceCommandHandler, get_command_suggestions


async def demo_voice_commands():
    """Demonstrate voice command processing."""
    print("=" * 70)
    print("🎙️  GDI Voice Commands + OpenClaw Integration Demo")
    print("=" * 70)
    print()
    
    # Initialize components
    print("[1/3] Initializing OpenClaw bridge...")
    bridge = OpenClawBridge()
    
    print("[2/3] Connecting to OpenClaw Gateway (port 18789)...")
    connected = await bridge.connect()
    
    if not connected:
        print("❌ Could not connect to OpenClaw Gateway")
        print("   Make sure OpenClaw is running: openclaw gateway --port 18789")
        return
    
    print("✅ Connected to OpenClaw!")
    print()
    
    print("[3/3] Initializing voice command handler...")
    handler = VoiceCommandHandler()
    handler.enabled = True
    print("✅ Voice command handler ready!")
    print()
    
    # Show available command categories
    print("=" * 70)
    print("📋 Available Command Categories")
    print("=" * 70)
    
    suggestions = get_command_suggestions()
    for category, commands in suggestions.items():
        print(f"\n{category.upper()}:")
        for cmd in commands[:3]:  # Show first 3 examples
            print(f"  • {cmd}")
    
    print()
    print("=" * 70)
    print("🎯 Demo: Executing Sample Commands")
    print("=" * 70)
    print()
    
    # Demo commands to try
    demo_commands = [
        "What time is it?",
        "What's the date?",
        "Open calculator",
        # "Create a simple HTML file",  # Uncomment for OpenClaw AI execution
    ]
    
    for i, cmd_text in enumerate(demo_commands, 1):
        print(f"\n[{i}/{len(demo_commands)}] Voice Command: \"{cmd_text}\"")
        print("-" * 70)
        
        # Process command
        command = await handler.process_command(
            command_text=cmd_text,
            session_id="demo",
            openclaw_bridge=bridge
        )
        
        # Show results
        print(f"Status: {command.status.value.upper()}")
        print(f"Response: {command.response}")
        if command.tools_used:
            print(f"Tools Used: {', '.join(command.tools_used)}")
        if command.error:
            print(f"Error: {command.error}")
        
        # Small delay between commands
        await asyncio.sleep(1)
    
    print()
    print("=" * 70)
    print("📊 Command Statistics")
    print("=" * 70)
    
    stats = handler.get_statistics()
    print(f"Total Commands: {stats['total_commands']}")
    print(f"Successful: {stats['successful']}")
    print(f"Failed: {stats['failed']}")
    print(f"Success Rate: {stats['success_rate']}%")
    
    print()
    print("=" * 70)
    print("🎉 Demo Complete!")
    print("=" * 70)
    print()
    print("Next Steps:")
    print("1. Start the GDI backend: ./start_backend.sh")
    print("2. Run the Flutter app: flutter run -d macos")
    print("3. Enable voice assistant in the UI")
    print("4. Say 'Jarvis' followed by your command!")
    print()
    print("For advanced AI commands (create websites, scripts, etc.):")
    print("→ Uncomment the advanced commands in this demo script")
    print("→ OpenClaw AI will use bash and computer tools to execute")
    print()
    
    # Cleanup
    await bridge.disconnect()


async def interactive_mode():
    """Interactive mode - type commands to test."""
    print("=" * 70)
    print("🎙️  GDI Voice Commands - Interactive Mode")
    print("=" * 70)
    print()
    print("Type commands to see how they would be processed.")
    print("Type 'quit' or 'exit' to stop.")
    print()
    
    # Initialize
    bridge = OpenClawBridge()
    connected = await bridge.connect()
    
    if not connected:
        print("⚠️  OpenClaw not connected - using basic command execution")
    else:
        print("✅ Connected to OpenClaw Gateway")
    
    print()
    
    handler = VoiceCommandHandler()
    handler.enabled = True
    
    # Interactive loop
    try:
        while True:
            print("-" * 70)
            cmd_text = input("Voice Command > ").strip()
            
            if cmd_text.lower() in ['quit', 'exit', 'q']:
                break
            
            if not cmd_text:
                continue
            
            # Process command
            print("Processing...")
            command = await handler.process_command(
                command_text=cmd_text,
                session_id="interactive",
                openclaw_bridge=bridge if connected else None
            )
            
            # Show results
            print(f"\n✓ Status: {command.status.value}")
            print(f"✓ Response: {command.response}")
            if command.error:
                print(f"✗ Error: {command.error}")
            print()
    
    except KeyboardInterrupt:
        print("\n\nInterrupted by user")
    
    finally:
        if connected:
            await bridge.disconnect()
        
        print()
        print("Session Statistics:")
        stats = handler.get_statistics()
        print(f"  Commands: {stats['total_commands']}")
        print(f"  Success Rate: {stats['success_rate']}%")


def main():
    """Main entry point."""
    import sys
    
    if len(sys.argv) > 1 and sys.argv[1] == "--interactive":
        asyncio.run(interactive_mode())
    else:
        asyncio.run(demo_voice_commands())


if __name__ == "__main__":
    main()
