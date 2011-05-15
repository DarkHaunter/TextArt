; Send contents of text file
#SingleInstance force

F12::
SendMode Input
SetKeyDelay 0, 0
Loop
{
    FileReadLine, line, text.txt, %A_Index%
    if ErrorLevel
        return
    StringSplit, characters, line
    ;Send %line%
    Sleep 50
    Send {Tab}
    Sleep 50
    ;SendRaw %line%
    Loop, %characters0%
    {
      this_character := characters%a_index%
      SendRaw %this_character%
      Sleep 2
    }
    Sleep 50
    Send {Enter}
    Sleep 50
}
