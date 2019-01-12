" TODO: compile commands under a master SeSwitch command with subcommands
"       eg SeSwitch open $seshname
" :SeSwitch $new_session   Close this session and open a new or existing one.
"                         Requires ! if this session is unnamed.
" TODO: completion
" TODO: if no session name given, switches to the previous session
" TODO: persist current/previous session across vim shutdown
command -nargs=1 -bang -complete=customlist,seswitch#SessionList SeSwitch
  \ call seswitch#SwitchSession('<bang>', '<args>')

" :SeClose           Close this session and leave all buffers bdel-ed.
"                         Requires ! if this session is unnamed.
command -nargs=0 -bang SeClose

" :SeSave $name      Save the current session with new name $name.
"                         Requires ! if the session file already exists.
" :SeSave            Update the saved session file for this session.
"                         ! is ignored if given.
command -nargs=? -bang SeSave call seswitch#SaveSession('<bang>', '<args>')

" :SeNew $name      Close this session and start a new one with name $name
"                         Requires ! if this session is unnamed
" :SeNew            Close this session and start a new unnamed one
"                         Requires ! if this session is unnamed
command -nargs=? -bang SeNew call seswitch#NewSession('<bang>', '<args>')


" TODO: autocompletion for session names in the SeSwitch command.

command SeDebug echo seswitch#Debug()
