%D \module
%D   [       file=mp-grph.mp,
%D        version=2000.12.14,
%D          title=\CONTEXT\ \METAPOST\ graphics,
%D       subtitle=graphic text support,
%D         author=Hans Hagen,
%D           date=\currentdate,
%D      copyright={PRAGMA / Hans Hagen \& Ton Otten}]
%C
%C This module is part of the \CONTEXT\ macro||package and is
%C therefore copyrighted by \PRAGMA. See licen-en.pdf for
%C details.

%D Under construction.

if unknown context_tool :    input mp-tool ; fi ;
if   known context_grph : endinput         ; fi ;

boolean context_grph ; context_grph := true ;

string CRLF ; CRLF := char 10 & char 13 ;

picture _currentpicture_ ;

def beginfig (expr c) =
  begingroup
  charcode := c ;
  resetfig ;
  scantokens extra_beginfig ;
enddef ;

def resetfig =
  clearxy ;
  clearit ;
  clearpen ;
  pickup defaultpen ;
  interim linecap := linecap ;
  interim linejoin := linejoin ;
  interim miterlimit := miterlimit ;
  save _background_ ; color _background_ ; _background_ :=  background  ;
  save  background  ; color  background  ;  background  := _background_ ;
  drawoptions () ;
enddef ;

def protectgraphicmacros =
  save showtext ;
  save beginfig ; let beginfig = begingraphictextfig ;
  save endfig   ; let endfig   = endgraphictextfig ;
  save end      ; let end      = relax ;
  interim prologues := prologues ;
  resetfig ; % resets currentpicture
enddef ;

numeric currentgraphictext ; currentgraphictext := 0 ;
string  graphictextformat  ; graphictextformat  := "plain" ;
string  graphictextstring  ; graphictextstring  := "" ;
string  graphictextfile    ; graphictextfile    := "dummy.mpo" ;

def savegraphictext (expr str) =
  graphictextfile := jobname & ".mpo" ;
  if (graphictextstring<>"") :
    write graphictextstring to graphictextfile ;
    graphictextstring := "" ;
  fi ;
  write str to graphictextfile ;
  let erasegraphictextfile = relax ;
enddef ;

def erasegraphictextfile =
  graphictextfile := jobname & ".mpo" ;
  write EOF to graphictextfile  ;
  let erasegraphictextfile = relax ;
enddef ;

extra_beginfig := extra_beginfig & " erasegraphictextfile ;" ;

def begingraphictextfig (expr n) =
  foundpicture := n ; scratchpicture := nullpicture ;
enddef ;

def endgraphictextfig =
  if foundpicture = currentgraphictext :
    expandafter endinput
  else :
    scratchpicture := nullpicture ;
  fi ;
enddef ;

def loadfigure primary filename =
  doloadfigure (filename)
enddef ;

def doloadfigure (expr filename) text figureattributes =
  begingroup ;
  save figurenumber, figurepicture, number, fixedplace ;
  numeric figurenumber  ; figurenumber  := 0 ;
  boolean figureshift ; figureshift := true ;
  picture figurepicture ; figurepicture := currentpicture ;
  def number primary n = hide(figurenumber := n) enddef ;
  def fixedplace = hide(figureshift := false) enddef ;
  protectgraphicmacros ;
  % defaults
  interim linecap    := rounded ;
  interim linejoin   := rounded ;
  interim miterlimit := 10 ;
  %
  currentpicture := nullpicture ;
  draw fullcircle figureattributes ; % expand number
  currentpicture := nullpicture ;
  def beginfig (expr n) =
    currentpicture := nullpicture ;
    if (figurenumber=n) or (figurenumber=0) :
      let endfig = endinput ;
    fi ;
  enddef ;
  let endfig = relax ;
  readfile(filename) ;
  if figureshift :
    currentpicture := currentpicture shifted -llcorner currentpicture ;
  fi ;
  addto figurepicture also currentpicture figureattributes ;
  currentpicture := figurepicture  ;
  endgroup ;
enddef ;

def graphictext primary t =
  dographictext(t)
enddef ;

def dographictext (expr t) =
  begingroup ;
  save figurepicture ; picture figurepicture ;
  figurepicture := currentpicture ; currentpicture := nullpicture ;
  if graphictextformat<>"" :
    graphictextstring :=
      "% format=" & graphictextformat & CRLF & graphictextstring ;
    graphictextformat := "" ;
  fi ;
  currentgraphictext := currentgraphictext + 1 ;
  savegraphictext ("\startTEXpage[scale=10000]" & t & "\stopTEXpage") ;
  dofinishgraphictext
enddef ;

def redographictext primary t =
  regraphictext(t)
enddef ;

def regraphictext (expr t) =
  begingroup ;
  save figurepicture ; picture figurepicture ;
  figurepicture := currentpicture ; currentpicture := nullpicture ;
  save currentgraphictext ; numeric currentgraphictext ;
  currentgraphictext := t ;
  dofinishgraphictext
enddef ;

%D Believe it or not, but it took me half a day to uncover
%D the following neccessity:
%D
%D \starttypen
%D save withfillcolor, withdrawcolor ;
%D \stoptypen
%D
%D When we have more than one graphictext, these will be
%D defined after the first graphic. For some obscure reason,
%D this means that in the next graphic they will be called, but
%D afterwards the data and boolean are not set. Don't ask me
%D why.

def dofinishgraphictext text x_op_x =
  protectgraphicmacros ; % resets currentpicture
  interim linecap    := butt ;     % normally rounded
  interim linejoin   := mitered ;  % normally rounded
  interim miterlimit := 10 ;       % todo
  let normalwithshade = withshade ;
  save foundpicture, scratchpicture, str ;
  save fill, draw, withshade, reversefill, outlinefill ;
  save withfillcolor, withdrawcolor ; % quite important
  numeric foundpicture ; picture scratchpicture ; string str ;
  def draw expr p =
    % the first, naive implementation was:
    %   addto scratchpicture doublepath p withpen currentpen ;
    % but it is better to turn lines into fills
    addto scratchpicture contour boundingbox
      image (addto currentpicture doublepath p withpen currentpen) ;
  enddef ;
  def fill expr p =
    addto scratchpicture contour p withpen currentpen ;
  enddef ;
  def f_op_f = enddef ; boolean f_color ; f_color := false ;
  def d_op_d = enddef ; boolean d_color ; d_color := false ;
  def s_op_s = enddef ; boolean s_color ; s_color := false ;
  boolean reverse_fill ; reverse_fill := false ;
  boolean outline_fill ; outline_fill := false ;
  def reversefill =
    hide(reverse_fill := true )
  enddef ;
  def outlinefill =
    hide(outline_fill := true )
  enddef ;
  def withshade primary c =
    hide(def s_op_s = normalwithshade c enddef ; s_color := true )
  enddef ;
  def withfillcolor primary c =
    hide(def f_op_f = withcolor c enddef ; f_color := true )
  enddef ;
  def withdrawcolor primary c =
    hide(def d_op_d = withcolor c enddef ; d_color := true )
  enddef ;
  scratchpicture := nullpicture ;
  addto scratchpicture doublepath origin x_op_x ; % pre-roll
  for i within scratchpicture : % Below here is a dirty tricky test!
    if (urcorner dashpart i) = origin : outline_fill := false ; fi ;
  endfor ;
  scratchpicture := nullpicture ;
  readfile(jobname & ".mpy") ;
  scratchpicture := (scratchpicture shifted -llcorner scratchpicture) scaled (1/10) ;
  if not d_color and not f_color : d_color := true ; fi
  if s_color : d_color := false ; f_color := false ; fi ;
  currentpicture := figurepicture ;
  if d_color and not reverse_fill :
    for i within scratchpicture :
      if f_color and outline_fill :
        addto currentpicture doublepath pathpart i _op_ x_op_x f_op_f
          dashed nullpicture ;
      fi ;
      if filled i :
        addto currentpicture doublepath pathpart i _op_ x_op_x d_op_d ;
      fi ;
    endfor ;
  fi ;
  if f_color :
    for i within scratchpicture :
      if filled i :
        addto currentpicture contour pathpart i _op_ x_op_x f_op_f
          withpen pencircle scaled 0 ;
      fi ;
    endfor ;
  fi ;
  if d_color and reverse_fill :
    for i within scratchpicture :
      if filled i :
        addto currentpicture doublepath pathpart i _op_ x_op_x d_op_d ;
      fi ;
    endfor ;
  fi ;
  if s_color :
    for i within scratchpicture :
      if filled i :
        addto currentpicture contour pathpart i _op_ x_op_x s_op_s ;
      fi ;
    endfor ;
  else :
    for i within scratchpicture :
      if stroked i :
        addto currentpicture doublepath pathpart i _op_ x_op_x d_op_d ;
      fi ;
    endfor ;
  fi ;
  endgroup ;
enddef ;

def resetgraphictextdirective =
  graphictextstring := "" ;
enddef ;

def graphictextdirective text t =
  graphictextstring := graphictextstring & t & CRLF ;
enddef ;

endinput

% example

input mp-grph ;

  graphictextformat := "context" ;
% graphictextformat := "plain" ;
% graphictextformat := "latex" ; graphictextdirective "\documentclass[]{article}" ;

beginfig (1) ;
  graphictext
    "\vbox{\hsize10cm \input tufte }"
    scaled 8
    withdrawcolor blue
    withfillcolor red
    withpen pencircle scaled 2pt ;
endfig ;

beginfig(1) ;
  loadfigure "gracht.mp" rotated 20 ;
  loadfigure "koe.mp" number 1 scaled 2 ;
endfig ;

end
