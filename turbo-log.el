;;; turbo-log.el --- a simple package for fast log selected region                     -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Artur Yaroshenko

;; Author: Artur Yaroshenko <artawower@protonmail.com>
;; Keywords: emacs, logger, print, console.log, fmt.Println
;; Version: 0.0.1

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package used for fast line/region logging with additional meta information

;;; Code:

;; code goes here

(defvar turbo-log--prefix)
(defvar turbo-log--modes)

(setq turbo-log--prefix "TCL: ")

(defun turbo-log--calculate-space-count (text)
  "Get space count at start of provided TEXT."
  (let* ((original-text-length (length text))
         (no-start-space-text (string-trim-left text))
         (no-start-space-text-length (length no-start-space-text)))
    (- original-text-length no-start-space-text-length)
    ))


(defun turbo-log--get-line-text (line-number)
  "Get text from LINE-NUMBER under point."
  (goto-line line-number)
  (thing-at-point 'line))

(defun turbo-log--ecmascript-is-return (text)
  "Check is TEXT container return keyword."
  (string-match "^[[:blank:]]*\\(return\\)[[:blank:]]+" text))

(defun turbo-log--has-text-linebreak (text)
  "Check is TEXT container \n."
  (string-match "\n" text))


(defun turbo-log--remove-semicolon-at-end (code)
  "Remove semicolon from provided CODE block."
  (let* ((code-len (length code))
         (last-char (substring code (- code-len 1) code-len)))

    (if (string= ";" last-char)
        (substring code 0 (- code-len 1))
      code)
    )
  )

(defun turbo-log--ecmascript-normilize-code (code)
  "Normalize CODE block for correct console.log func."
  (let* ((code (replace-regexp-in-string "[[:blank:]]*=[[:blank:]]*.+" "" code))
         (code (replace-regexp-in-string "\\(const\\|let\\|public\\|protected\\|private\\|var\\)[[:blank:]]+" "" code))
         ;; Remove type for typescript
         (code (replace-regexp-in-string "\\:[[:blank:]].+" "" code)))
    (turbo-log--remove-semicolon-at-end code)
    ))

(defun turbo-log--ecmascript-find-insert-pos (current-line-number text)
  "Calculate insert position by CURRENT-LINE-NUMBER and TEXT from previous line."
  (message "Return found: %s" (turbo-log--ecmascript-is-return text))
  (if (turbo-log--ecmascript-is-return text)
      (- current-line-number 1)
    current-line-number
    )
  )

(defun turbo-log--get-selected-text ()
  "Return selected text."
  (string-trim (buffer-substring (region-beginning) (region-end))))

(defun turbo-log--get-current-line-number ()
  "Return current line number after select.  Depend on full line selected or region."
  (if (bolp)
      (line-number-at-pos)
    (+ (line-number-at-pos) 1)
    ))


(defun turbo-log--ecmascript-print (current-line-number raw-selected-text formatted-selected-text prev-line-text)
  "Console log for ecmascript, js/ts modes."
  (let* ((insert-line-number (turbo-log--ecmascript-find-insert-pos current-line-number prev-line-text))
         (insert-line-space-count (turbo-log--calculate-space-count (turbo-log--get-line-text insert-line-number)))
         (additional-spaces (make-string insert-line-space-count ? ))
         (line-number-text (concat "[line " (format "%s" insert-line-number) "] "))
         (normalized-code (turbo-log--ecmascript-normilize-code formatted-selected-text))
         (turbo-log--message
          (concat
           additional-spaces
           "console.log('"
           line-number-text
           turbo-log--prefix formatted-selected-text ": ', "
           normalized-code ")\n"))
         )



    (goto-line insert-line-number)
    (insert turbo-log--message)
    ))


(setq turbo-log--modes '((typescript-mode . turbo-log--ecmascript-print)
                         (js-mode . turbo-log--ecmascript-print)
                         (ng2-ts-mode . turbo-log--ecmascript-print)
                         (org-mode . turbo-log--ecmascript-print)
                         (python-mode . turbo-log--python-print)))

(defun turbo-log--chose-mode ()
  "Chose logger by current major mode."
  (let* ((logger (assoc major-mode turbo-log--modes)))
    (if (eq logger nil)
        (funcall (lambda () (message "Logger for mode %s is not found" major-mode)
                   logger))
      logger)
    ))

(defun turbo-log--handle-logger (logger-func)
  "Common entrypoint for all loggers by provieded LOGGER-FUNC."
  (let* ((current-line-number (turbo-log--get-current-line-number))
         (raw-selected-text (turbo-log--get-selected-text))
         (formatted-selected-text (string-trim raw-selected-text))
         (prev-line-text (turbo-log--get-line-text (- current-line-number 1)))
         )
    (funcall logger-func
             current-line-number
             raw-selected-text
             formatted-selected-text
             prev-line-text)
    )
  )

;;;###autoload
(defun turbo-log-print ()
  "Log selected region for current major mode."
  (interactive)
  (let* ((logger-list (turbo-log--chose-mode))
         (logger (cdr logger-list)))
    (if logger
        (turbo-log--handle-logger logger)
      )
    ))

(define-key global-map (kbd "C-s-l") 'turbo-log-print)

;;; _
(provide 'turbo-log)
;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; turbo-log.el ends here
