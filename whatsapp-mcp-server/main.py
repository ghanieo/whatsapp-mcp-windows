from typing import List, Dict, Any, Optional
from mcp.server.fastmcp import FastMCP
from whatsapp import (
    list_messages as whatsapp_list_messages,
    list_chats as whatsapp_list_chats,
    get_chat as whatsapp_get_chat,
    get_message_context as whatsapp_get_message_context,
    send_message as whatsapp_send_message,
    send_file as whatsapp_send_file,
    send_audio_message as whatsapp_audio_voice_message,
    download_media as whatsapp_download_media
)

import os
import sqlite3
from whatsapp import MESSAGES_DB_PATH

# Initialize FastMCP server
mcp = FastMCP("whatsapp")

# Chat allowlist: every tool only reads from / sends to these JIDs (one per line, "#" comments).
# A line "*" allows every chat. Missing or empty file = no chat allowed (fail closed).
# Kept out of git (contains phone numbers).
ALLOWED_CHATS_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "allowed_chats.txt")


def allowed_jids() -> List[str]:
    try:
        with open(ALLOWED_CHATS_FILE, encoding="utf-8") as f:
            lines = (line.split("#", 1)[0].strip() for line in f)
            return [line for line in lines if line]
    except FileNotFoundError:
        return []


def normalize_jid(recipient: str) -> str:
    # A bare phone number is sent by the bridge as <number>@s.whatsapp.net
    return recipient if "@" in recipient else f"{recipient}@s.whatsapp.net"


def allow_all() -> bool:
    return "*" in allowed_jids()


def is_allowed(jid: Optional[str]) -> bool:
    return bool(jid) and (allow_all() or normalize_jid(jid) in allowed_jids())


def denied(jid: Optional[str]) -> Dict[str, Any]:
    return {"success": False, "message": f"Chat {jid} is not in allowed_chats.txt"}


def chat_of_message(message_id: str) -> Optional[str]:
    conn = sqlite3.connect(f"file:{MESSAGES_DB_PATH}?mode=ro", uri=True)
    try:
        row = conn.execute("SELECT chat_jid FROM messages WHERE id = ?", (message_id,)).fetchone()
        return row[0] if row else None
    finally:
        conn.close()


@mcp.tool()
def list_messages(
    after: Optional[str] = None,
    before: Optional[str] = None,
    sender_phone_number: Optional[str] = None,
    chat_jid: Optional[str] = None,
    query: Optional[str] = None,
    limit: int = 20,
    page: int = 0,
    include_context: bool = True,
    context_before: int = 1,
    context_after: int = 1
) -> List[Dict[str, Any]]:
    """Get WhatsApp messages matching specified criteria with optional context.
    
    Args:
        after: Optional ISO-8601 formatted string to only return messages after this date
        before: Optional ISO-8601 formatted string to only return messages before this date
        sender_phone_number: Optional phone number to filter messages by sender
        chat_jid: Optional chat JID to filter messages by chat (must be in allowed_chats.txt;
                  omitted = every allowed chat)
        query: Optional search term to filter messages by content
        limit: Maximum number of messages to return per chat (default 20)
        page: Page number for pagination (default 0)
        include_context: Whether to include messages before and after matches (default True)
        context_before: Number of messages to include before each match (default 1)
        context_after: Number of messages to include after each match (default 1)
    """
    if chat_jid and not is_allowed(chat_jid):
        return denied(chat_jid)
    if chat_jid:
        jids = [normalize_jid(chat_jid)]
    else:
        jids = [None] if allow_all() else allowed_jids()
    results = []
    for jid in jids:
        messages = whatsapp_list_messages(
            after=after,
            before=before,
            sender_phone_number=sender_phone_number,
            chat_jid=jid,
            query=query,
            limit=limit,
            page=page,
            include_context=include_context,
            context_before=context_before,
            context_after=context_after
        )
        results.append(f"=== {jid or 'all chats'} ===\n{messages}")
    return "\n\n".join(results)

@mcp.tool()
def list_chats(query: Optional[str] = None, limit: int = 20) -> List[Dict[str, Any]]:
    """List the WhatsApp chats this server may access (from allowed_chats.txt), with their last message.

    Args:
        query: Optional search term on chat name or JID (only used when allowed_chats.txt contains "*")
        limit: Maximum number of chats to return when every chat is allowed (default 20)
    """
    if allow_all():
        return whatsapp_list_chats(query=query, limit=limit)
    return [whatsapp_get_chat(jid, True) for jid in allowed_jids()]

@mcp.tool()
def get_chat(chat_jid: str, include_last_message: bool = True) -> Dict[str, Any]:
    """Get WhatsApp chat metadata by JID.

    Args:
        chat_jid: The JID of the chat to retrieve (must be in allowed_chats.txt)
        include_last_message: Whether to include the last message (default True)
    """
    if not is_allowed(chat_jid):
        return denied(chat_jid)
    chat = whatsapp_get_chat(normalize_jid(chat_jid), include_last_message)
    return chat

@mcp.tool()
def get_message_context(
    message_id: str,
    before: int = 5,
    after: int = 5
) -> Dict[str, Any]:
    """Get context around a specific WhatsApp message.
    
    Args:
        message_id: The ID of the message to get context for
        before: Number of messages to include before the target message (default 5)
        after: Number of messages to include after the target message (default 5)
    """
    chat_jid = chat_of_message(message_id)
    if not is_allowed(chat_jid):
        return denied(chat_jid)
    context = whatsapp_get_message_context(message_id, before, after)
    return context

@mcp.tool()
def send_message(
    recipient: str,
    message: str
) -> Dict[str, Any]:
    """Send a WhatsApp message to a person or group. For group chats use the JID.

    Args:
        recipient: The recipient - either a phone number with country code but no + or other symbols,
                 or a JID (e.g., "123456789@s.whatsapp.net" or a group JID like "123456789@g.us")
        message: The message text to send
    
    Returns:
        A dictionary containing success status and a status message
    """
    # Validate input
    if not recipient:
        return {
            "success": False,
            "message": "Recipient must be provided"
        }
    if not is_allowed(recipient):
        return denied(recipient)

    # Call the whatsapp_send_message function with the unified recipient parameter
    success, status_message = whatsapp_send_message(recipient, message)
    return {
        "success": success,
        "message": status_message
    }

@mcp.tool()
def send_file(recipient: str, media_path: str) -> Dict[str, Any]:
    """Send a file such as a picture, raw audio, video or document via WhatsApp to the specified recipient. For group messages use the JID.
    
    Args:
        recipient: The recipient - either a phone number with country code but no + or other symbols,
                 or a JID (e.g., "123456789@s.whatsapp.net" or a group JID like "123456789@g.us")
        media_path: The absolute path to the media file to send (image, video, document)
    
    Returns:
        A dictionary containing success status and a status message
    """
    if not is_allowed(recipient):
        return denied(recipient)

    # Call the whatsapp_send_file function
    success, status_message = whatsapp_send_file(recipient, media_path)
    return {
        "success": success,
        "message": status_message
    }

@mcp.tool()
def send_audio_message(recipient: str, media_path: str) -> Dict[str, Any]:
    """Send any audio file as a WhatsApp audio message to the specified recipient. For group messages use the JID. If it errors due to ffmpeg not being installed, use send_file instead.
    
    Args:
        recipient: The recipient - either a phone number with country code but no + or other symbols,
                 or a JID (e.g., "123456789@s.whatsapp.net" or a group JID like "123456789@g.us")
        media_path: The absolute path to the audio file to send (will be converted to Opus .ogg if it's not a .ogg file)
    
    Returns:
        A dictionary containing success status and a status message
    """
    if not is_allowed(recipient):
        return denied(recipient)
    success, status_message = whatsapp_audio_voice_message(recipient, media_path)
    return {
        "success": success,
        "message": status_message
    }

@mcp.tool()
def download_media(message_id: str, chat_jid: str) -> Dict[str, Any]:
    """Download media from a WhatsApp message and get the local file path.
    
    Args:
        message_id: The ID of the message containing the media
        chat_jid: The JID of the chat containing the message
    
    Returns:
        A dictionary containing success status, a status message, and the file path if successful
    """
    if not is_allowed(chat_jid):
        return denied(chat_jid)
    if chat_of_message(message_id) != normalize_jid(chat_jid):
        return {"success": False, "message": f"Message {message_id} is not in chat {chat_jid}"}
    file_path = whatsapp_download_media(message_id, chat_jid)
    
    if file_path:
        return {
            "success": True,
            "message": "Media downloaded successfully",
            "file_path": file_path
        }
    else:
        return {
            "success": False,
            "message": "Failed to download media"
        }

if __name__ == "__main__":
    # Initialize and run the server
    mcp.run(transport='stdio')