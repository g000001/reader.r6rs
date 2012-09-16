;;;; reader.r6rs.lisp

(cl:in-package :reader.r6rs.internal)
(in-readtable :standard)

(def-suite reader.r6rs)

(in-suite reader.r6rs)

;;; "reader.r6rs" goes here. Hacks and glory await!

(declaim (ftype (function (stream) 
                          (values (or fixnum null) &optional)) 

                Read-hex-scalar-value)
         
         (ftype (function (stream character)
                          (values simple-string &optional)) 

                Read-r6rs-string))


#|
<string element> → <any character other than " or \>
         | \a | \b | \t | \n | \v | \f | \r
         | \" | \\
         | \<intraline whitespace>*<line ending>
            <intraline whitespace>*
         | <inline hex escape>

<inline hex escape> → \x<hex scalar value>;
<hex scalar value> → <hex digit>+
|#


(defun Read-hex-scalar-value (STREAM &aux (DELIM #\;))
  (loop :for C := (read-char STREAM t nil)
        :until (and C (char= DELIM C))
        :collect C :into CS
        :finally (return
                   (values (parse-integer (coerce CS 'string)
                                          :radix 16.)))))


(defun Read-r6rs-string (STREAM CHAR &aux (DELIM #\"))
  (declare (ignore CHAR))
  (let ((ESC nil)
        (ANS (make-array 0
                         :element-type 'character
                         :fill-pointer 0
                         :adjustable t)) )
    (loop :for c := (read-char STREAM t nil)
          :until (and C (or ESC (char= DELIM C)))
          :if (and C (char= #\\ C))
            :do (progn
                  (setq C (read-char STREAM t nil))
                  (vector-push-extend (case C
                                        (#\a #\Bel)
                                        (#\b #\Backspace)
                                        (#\t #\Tab)
                                        (#\n #\Newline)
                                        (#\v #\Vt)
                                        (#\f #\Page)
                                        (#\r #\Return)
                                        (#\" #\")
                                        (#\\ #\\)
                                        (#\x (code-char
                                              (Read-hex-scalar-value STREAM) ))
                                        (otherwise 
                                         (error "invalid escape sequence, ~C" C )))
                                      ANS ))
          :else :do (vector-push-extend C ANS))
    (coerce ANS 'simple-string) ))


#|(defmethod print-object ((OBJ string) STREAM)
  (flet ((Esc (CHAR)
           (princ #\\ STREAM)
           (princ CHAR STREAM)))
    (when *print-escape* (princ #\" STREAM))
    (loop :for C :across OBJ 
          :do (case C
                (#\Bel (Esc #\a))
                (#\Backspace (Esc #\b))
                (#\Tab (Esc #\t))
                (#\Newline (Esc #\n))
                (#\Vt (Esc #\v))
                (#\Page (Esc #\f))
                (#\Return (Esc #\r))
                (#\" (Esc #\"))
                (#\\ (Esc #\\))
                (otherwise (princ C STREAM)) ))
    (when *print-escape* (princ #\" STREAM))
    OBJ) )|#


;;; eof

