let g:seswitch#session_file_extension = '.vimsession'

function! seswitch#Debug()
  return {'current_session': exists('g:seswitch#current_session') ?
          \ g:seswitch#current_session : 'NONE',
        \ 'session_dir': exists('g:seswitch#session_dir') ?
          \ g:seswitch#session_dir : 'NONE',
        \ 'device_name': exists('g:seswitch#device_name') ?
          \ g:seswitch#device_name : 'NONE',
        \ 'SwitchSession': function('seswitch#SwitchSession'),
        \ 'CloseSession': function('seswitch#CloseSession'),
        \ 'OpenSession': function('seswitch#OpenSession')    }
endfunction

" Returns a list of completion options for SessionSwitch.
" This is based on the existing session files in the session file dir
"   that have the device prefix of this device.
function! seswitch#SessionList(ArgLead, CmdLine, CursorPos)
  return seswitch#ListDeviceSessions(g:seswitch#session_dir,
                                   \ g:seswitch#device_name,
                                   \ a:ArgLead)

endfunction


" Handler for SeSwitch command
function! seswitch#SwitchSession(bangstr, new_session_name)
  let bang = (a:bangstr == '!')
  let new = a:new_session_name
  if new == ''
    if exists('g:seswitch#previous_session') && g:seswitch#previous_session != ''
      let new = g:seswitch#previous_session
    else
      throw "SeSwitch: No previous session to switch to.  Use :SeSwitch NEW_SESSION."
    endif
  endif
  if !bang && exists('g:seswitch#current_session')
    call seswitch#SaveSession('', '')
  endif
  %bdel
  if exists('g:seswitch#current_session')
    let g:seswitch#previous_session = g:seswitch#current_session
  endif
  call seswitch#OpenSession(new)
endfunction

" :SeSave $name      Save the current session with name $name.
"                    Requires ! if the session file already exists.
" :SeSave            Update the saved session file for this session.
"                    ! is ignored if given.
" TODO: see if there's a cleaner way to test for file existence
function! seswitch#SaveSession(bangstr, new_session_name)
  let bang = (a:bangstr == '!')
  let name_given = (a:new_session_name != '')

  if name_given
    let session_filename = seswitch#SessionPath(g:seswitch#session_dir,
      \ g:seswitch#device_name, a:new_session_name)
    if (glob(session_filename) != '') && !bang
      echoerr "Session file already exists for given session name."
      echoerr "Use :SeSave! to confirm."
      throw "SeSwitch: can't overwrite existing session without !"
    endif
    let g:seswitch#current_session = a:new_session_name
  else
    if exists('g:seswitch#current_session')
      let session_filename = g:seswitch#SessionPath(g:seswitch#session_dir,
        \ g:seswitch#device_name, g:seswitch#current_session)
    else
      throw "seswitch: can't save with no session name"
    endif
  endif

  execute "mksession! " . session_filename
endfunction

" Starts a session named session_name
" If there is a session file for that name and this device, sources it
" Expects no open buffers prior to execution
function! seswitch#OpenSession(session_name)
  let session_filename = g:seswitch#SessionPath(g:seswitch#session_dir,
    \ g:seswitch#device_name, a:session_name)
  if glob(session_filename) != ''
    execute "source " . session_filename
    echomsg "Sourced session file for session '" . a:session_name . "'."
  else
    echomsg "No session file found for session '" . a:session_name . "'."
  endif
  let g:seswitch#current_session = a:session_name
  echomsg "Current session now '" . g:seswitch#current_session . "'."
endfunction

" :SeNew $name      Close this session and start a new one with name $name
"                   Requires ! if this session is unnamed
" :SeNew            Close this session and start a new unnamed one
"                   Requires ! if this session is unnamed
function! seswitch#NewSession(bangstr, new_session_name)
  let bang = (a:bangstr == '!')
  let name_given = (a:new_session_name != '')

  if exists('g:seswitch#current_session')
    call seswitch#SaveSession('', '')
  else
    if !bang
      echomsg "Current session is unnamed."
      echomsg "Use :SeNew! to override."
      throw "SeNew: can't close existing unnamed session without bang."
    endif
  endif

  %bdel
  if name_given
    let g:seswitch#current_session = a:new_session_name
  else
    if exists('g:seswitch#current_session')
      unlet g:seswitch#current_session
    endif
  endif
endfunction


""{ Next two functions are aware of the format for session filenames

" TODO: make path separator cross-platform portable
function! seswitch#SessionPath(session_dir, device_name, session_name)
  return a:session_dir . '/' . 'device--' . a:device_name . '/' . a:session_name . g:seswitch#session_file_extension
endfunction

" Extract the session name from a full session path+filename
function! seswitch#SessionNameFromPath(session_path)
  let result = substitute(a:session_path, '^.*/', '', '')
  let extpos = strridx(result, g:seswitch#session_file_extension)
  if extpos < 0
    throw 'SeSwitch: session file extension "' . g:seswitch#session_file_extension
        \ . '" not found in session path "' . a:session_path . '"'
  endif
  return result[0:extpos-1]
endfunction
""}

" Returns a list of session names for the given device.
" Third argument, if given, is a prefix on the session name used for autocompletion.
function! seswitch#ListDeviceSessions(session_dir, device_name, ...)
  let prefix = a:0 ? fnameescape(a:1) : ''
  let session_dir = fnameescape(a:session_dir)
  let device_name = fnameescape(a:device_name)
  let globpath = seswitch#SessionPath(session_dir, device_name, prefix . "*")
  let files = glob(globpath, 0, 1)
  return map(files, "seswitch#SessionNameFromPath(v:val)")
endfunction

" Uhh pretty sure I don't need this anymore
"   if a:0
"     let seswitch#current_session = a:1
"   endif
"   if exists('seswitch#current_session')
"     mksession! seswitch#SessionPath(seswitch#session_dir, seswitch#device_name,
"       \ seswitch#current_session)
"   else
"     echoerr "Can't save unnamed session."
"     echoerr "Usage: :SessionSave NEW_SESSION_NAME"
"   endif

" " _ old
" 
" " Usage
" " :SeSwitch $new_session   Close this session and start a new one.
" "                         Requires ! if this session is unnamed.
" " :SessionClose           Close this session and leave all buffers bdel-ed.
" "                         Requires ! if this session is unnamed.
" " :SessionSave $name      Save the current session with name $name.
" "                         Requires ! if the session file already exists.
" " :SessionSave            Update the saved session file for this session.
" 
" 
" " TODO: make it take bang! to close an unnamed session
" " TODO: verify that the new session file exists
" " Switches to a new session.
" " Refuses to do so if there is no name for the session.
" " This is to prevent accidentally wiping out the session state.
" function seswitch#SwitchSession(new_session_name)
"   if !exists(seswitch#current_session) && !a:bang
"     echoerr "SeSwitch: Current session is unnamed."
"     echoerr "Use :SaveSession to set name or use SeSwitch! to switch."
"   else
" 
"   if exists(seswitch#current_session)
"     call seswitch#SaveSession()
"   endif
" 
"   bufdo bdel
"   source seswitch#SessionPath(seswitch#session_dir, seswitch#device_name,
"     \ a:new_session_name)
"   let seswitch#current_session = a:new_session_name
" endfunction
" 
" " Creates a new session, closing the current one first.
" function seswitch#NewSession(new_session_name)
" 
" " TODO: check for modified buffers
" " TODO: figure out how to remove buffers from getbufinfo() results
" " TODO: This whole function might be unnecessary.
" function seswitch#CloseSession()
"   if exists('seswitch#current_session')
"     bufdo bdel
"     unlet seswitch#current_session
"   else
"     throw 'SessionSwitch: cannot close unnamed session.'
" endfunction
" 
" " Save the current session, setting the current session name to a:1 if it's given.
" " Overwrites the saved session file even without a bang
" " a:session_name sets the current session name
" " If there is already a session name, and a session name is given, the session is saved again with a different name.
" " If there is a session name and none is given, the saved session is updated.
" " If there is no session name, and none is given, an error message is output.
" function seswitch@SaveSession(...)
"   if a:0
"     let seswitch#current_session = a:1
"   endif
"   if exists('seswitch#current_session')
"     mksession! seswitch#SessionPath(seswitch#session_dir, seswitch#device_name,
"       \ seswitch#current_session)
"   else
"     echoerr "Can't save unnamed session."
"     echoerr "Usage: :SessionSave NEW_SESSION_NAME"
"   endif
" endfunction
