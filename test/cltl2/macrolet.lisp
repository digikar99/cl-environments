;;;; macrolet.lisp
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

;;;; Test that environment information is extracted from MACROLET and SYMBOL-MACROLET forms.

(defpackage :cl-environments.test.cltl2.macrolet-forms
  (:use :cl-environments-cl
	:cl-environments.test.cltl2
	:fiveam))

(in-package :cl-environments.test.cltl2.macrolet-forms)

(def-suite macrolet-forms
    :description "Test extraction of environment information from MACROLET and SYMBOL-MACROLET forms"
    :in cltl2-test)

(in-suite macrolet-forms)

(defmacro test-macro (form)
  form)

(defun global-fn (a b c)
  (/ (* a b) c))

(define-symbol-macro global-symbol-macro "Hello World")

(test macro-types
  "Test extracting lexical macro information"

  (macrolet ((pass-through (form)
	       "Pass through macro"
	       form))

    (is (info= (info function pass-through)
	       '(:macro t nil)))))

(test macro-shadowing
  "Test shadowing of global macros by lexical macros"

  (is (info= (info function test-macro)
	     '(:macro nil nil)))

  (macrolet ((test-macro (form)
	       form))

    (is (info= (info function test-macro)
	       '(:macro t nil)))))

(test function-shadowing
  "Test shadowing of global functions by lexical macros"

  (is (info= (info function global-fn)
	     '(:function nil nil)))

  (macrolet ((global-fn (form)
	       form))

    (is (info= (info function global-fn)
	       '(:macro t nil)))))

(test symbol-macro-types
  "Test extraction of lexical symbol macro information"

  (symbol-macrolet ((sym-macro "a symbol macro")
		    (sym-macro2 2))

    (is-every info=
      ((info variable sym-macro) '(:symbol-macro t nil))
      ((info variable sym-macro2) '(:symbol-macro t nil)))))

(test symbol-macro-shadowing
  "Test shadowing of global symbol macros with lexical symbol macros"

  (is (info= (info variable global-symbol-macro)
	     '(:symbol-macro nil nil)))

  (symbol-macrolet ((global-symbol-macro "Local symbol macro"))
    (is (info= (info variable global-symbol-macro)
	       '(:symbol-macro t nil)))))

(test var-shadow-symbol-macro
  "Test shadowing of symbol macros with lexical variables"

  (symbol-macrolet ((sym-macro "macro"))
    (is (info= (info variable sym-macro)
	       '(:symbol-macro t nil)))

    (let ((sym-macro 1))
      (declare (type integer sym-macro))

      (is (info= (info variable sym-macro)
		 '(:lexical t ((type . integer))))))))
