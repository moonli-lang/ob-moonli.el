;;; ob-moonli.el --- Babel Functions for Moonli   -*- lexical-binding: t; -*-

;; Copyright (C) 2009-2025 Free Software Foundation, Inc.
;; Copyright (C) 2026 Shubhamkar Ayare

;; Authors: Shubhamkar Ayare <digikar@proton.me>
;; Keywords: literate programming, reproducible research
;; URL: https://orgmode.org

;; This file is adapted from ob-lisp.el, which is part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; It is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;;; Support for evaluating Moonli code, relies on SLY or SLIME
;;; for all eval.

;;; Requirements:

;; Requires SLY (Sylvester the Cat's Common Lisp IDE) or SLIME
;; (Superior Lisp Interaction Mode for Emacs).  See:
;; - https://github.com/capitaomorte/sly
;; - https://common-lisp.net/project/slime/

;;; Code:

(require 'org-macs)
(org-assert-version)

(require 'ob)
(require 'org-macs)
(require 'ob-lisp)

(defun org-babel-execute:moonli (body params)
  "Execute a block of Moonli code with Babel.
BODY is the contents of the block, as a string.  PARAMS is
a property list containing the parameters of the block."
  (let (eval-and-grab-output)
    (pcase org-babel-lisp-eval-fn
      (`slime-eval (org-require-package 'slime "SLIME")
                   (setq eval-and-grab-output 'swank:eval-and-grab-output))
      (`sly-eval (org-require-package 'sly "SLY")
                 (setq eval-and-grab-output 'slynk:eval-and-grab-output)))
    (org-babel-reassemble-table
     (let ((result
            (funcall (if (member "output" (cdr (assq :result-params params)))
                         #'car #'cadr)
                     (with-temp-buffer
                       (insert (org-babel-expand-body:lisp body params))
                       (funcall org-babel-lisp-eval-fn
                                `(,eval-and-grab-output
                                  ,(let ((dir (if (assq :dir params)
                                                  (cdr (assq :dir params))
                                                default-directory)))
                                     (format
                                      (if dir (format org-babel-lisp-dir-fmt dir)
                                        "(progn %s\n)")
                                      `(eval
                                        (moonli:read-moonli-from-string
                                         ,(prin1-to-string
                                           (string-trim (buffer-substring-no-properties
                                                         (point-min) (point-max))
                                                        "[ \t\n\r]+" "[ ;\t\n\r]+")))))))
                                (cdr (assq :package params)))))))
       (org-babel-result-cond (cdr (assq :result-params params))
         (org-strip-quotes result)
         (condition-case nil
             (read (org-babel-lisp-vector-to-list result))
           (error result))))
     (org-babel-pick-name (cdr (assq :colname-names params))
                          (cdr (assq :colnames params)))
     (org-babel-pick-name (cdr (assq :rowname-names params))
                          (cdr (assq :rownames params))))))

(provide 'ob-moonli)

;;; ob-moonli.el ends here
