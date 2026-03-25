" syntax/jcl.vim - Basic JCL syntax highlighting

if exists('b:current_syntax')
  finish
endif
let b:current_syntax = 'jcl'

" JCL statements start in column 1-2 with //
syntax match jclStatement   /^\/\/[^ ]*/         contains=jclName
syntax match jclName        /^\/\/\zs[^ ]*/       contained
syntax match jclComment     /^\/\/\*.*/
syntax match jclContinue    /^\/\/ /
syntax match jclOperation   /\s\+\zs\(JOB\|EXEC\|DD\|PROC\|PEND\|IF\|ELSE\|ENDIF\|SET\|INCLUDE\|JCLLIB\|OUTPUT\|COMMAND\|XMIT\|NOTIFY\)\ze\s*/
syntax match jclParameter   /\w\+=/
syntax match jclString      /'[^']*'/
syntax match jclContinued   /,$\|,$\s*$/

highlight default link jclStatement   Keyword
highlight default link jclName        Identifier
highlight default link jclComment     Comment
highlight default link jclContinue    Special
highlight default link jclOperation   Statement
highlight default link jclParameter   Type
highlight default link jclString      String
highlight default link jclContinued   Special
