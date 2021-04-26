;;;; letstar.lisp
;;;;
;;;; Copyright 2021 Alexander Gutev
;;;;
;;;; Permission is hereby granted, free of charge, to any person
;;;; obtaining a copy of this software and associated documentation
;;;; files (the "Software"), to deal in the Software without
;;;; restriction, including without limitation the rights to use,
;;;; copy, modify, merge, publish, distribute, sublicense, and/or sell
;;;; copies of the Software, and to permit persons to whom the
;;;; Software is furnished to do so, subject to the following
;;;; conditions:
;;;;
;;;; The above copyright notice and this permission notice shall be
;;;; included in all copies or substantial portions of the Software.
;;;;
;;;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;;;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
;;;; OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;;;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
;;;; HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
;;;; WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
;;;; FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
;;;; OTHER DEALINGS IN THE SOFTWARE.

;;;; Test that environment information is extracted from LET* forms

(defpackage :cl-environments.test.cltl2.let*-forms
  (:use :cl-environments-cl
	:cl-environments.test.cltl2
	:fiveam))

(in-package :cl-environments.test.cltl2.let*-forms)

(def-suite let*-forms
    :description "Test extraction of environment information from LET* forms"
    :in cltl2-test)

(in-suite let*-forms)

(defvar *global-var* "hello world")

(test let*-binding-types
  (let* ((x 1)
	 (y "hello"))
    (declare (type integer x)
	     (type string y))

    (is (info=
	 '(:lexical t ((type . integer)))
	 (info variable x)))

    (is (info=
    	 '(:lexical t ((type . string)))
    	 (info variable y)))

    (is (info=
	 '(:special nil nil)
	 (info variable *global-var*)))

    (is (info=
    	 '(nil nil nil)
    	 (info variable z)))))

(test let*-binding-special
  (let* ((dvar (+ 1 2))
	 (lvar (+ 2 3))
	 (*global-var* "bye"))
    (declare (special dvar)
	     (type number lvar dvar))

    (is (info=
	 #-sbcl '(:special t ((type . number)))
	 #+sbcl '(:special nil ((type . number)))

	 (info variable dvar)))

    (is (info=
	 '(:lexical t ((type . number)))
	 (info variable lvar)))

    (is (info=
	 #-sbcl '(:special t nil)
	 #+sbcl '(:special nil nil)

	 (info variable *global-var*)))))

(test let*-binding-dynamic-extent
  (let* ((func (lambda (a b) (+ a b))))
    (declare (dynamic-extent func)
	     (type (function (number number) number) func))

    (is (info=
	 ;; CMUCL ignores DYNAMIC-EXTENT here
	 #-cmucl '(:lexical t ((dynamic-extent . t)
			       (type . (function (number number) number))))

	 #+cmucl '(:lexical t ((type . (function (number number) number))))

	 (info variable func)))))

(test let*-info-in-init-form
  (let ((outer-var (* 8 7)))
    (declare (type integer outer-var))

    (let* ((a (progn
		(is (info=
		     '(:lexical t ((type . integer)))
		     (info variable outer-var)))
		1))

	   (b (progn
		(is (info=
		     '(:lexical t ((type . integer)))
		     (info variable outer-var)))

		(is (info=
		     '(:lexical t nil)
		     (info variable a)))))

	  (outer-var "string"))

      (declare (special outer-var)
	       (type string outer-var)
	       (dynamic-extent outer-var))

      (is (info=
	   #-(or sbcl cmucl) '(:special t ((dynamic-extent . t) (type . string)))
	   #+sbcl '(:special nil ((type . string)))
	   #+cmucl '(:special t ((type . string)))

	   (info variable outer-var))))))
