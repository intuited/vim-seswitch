command -nargs=? -bang -complete=customlist,seswitch#SessionList SeSwitch
  \ call seswitch#SwitchSession('<bang>', <q-args>)

" :SeClose           Close this session and leave all buffers bdel-ed.
"                         Requires ! if this session is unnamed.
command -nargs=0 -bang SeClose

" :SeSave $name      Save the current session with new name $name.
"                         Requires ! if the session file already exists.
" :SeSave            Update the saved session file for this session.
"                         ! is ignored if given.
command -nargs=? -bang SeSave call seswitch#SaveSession('<bang>', <q-args>)

" :SeNew $name      Close this session and start a new one with name $name
"                         Requires ! if this session is unnamed
" :SeNew            Close this session and start a new unnamed one
"                         Requires ! if this session is unnamed
command -nargs=? -bang SeNew call seswitch#NewSession('<bang>', <q-args>)


" TODO: autocompletion for session names in the SeSwitch command.

command SeDebug echo seswitch#Debug()

" List the saved sessions for this device.
command SeList echo join(seswitch#ListDeviceSessions(seswitch#session_dir,
                                                   \ seswitch#device_name), "\n")
