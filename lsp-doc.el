;;; lsp-doc.el --- LSP doc converter -*- lexical-binding: t; -*-

;; Keywords: languages, tool
;; Package-Requires: ((emacs "25.1") (dash "2.14.1") (dash-functional "2.14.1") (f "0.20.0") (ht "2.0") (spinner "1.7.3") (markdown-mode "2.3") (lv "0"))
;; Version: 6.4

;; URL: https://github.com/emacs-lsp/lsp-mode
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Tool for convert elisp files into documentation.

;;; Code:

(require 'f)
(require 'dash)
(require 'seq)
(require 'ht)
(require 'lsp-clients)

(defun lsp-doc--clients ()
  "Return a list of hash-map of all clients."
(let ((json-array-type 'vector)
      (json-object-type 'hash-table)
      (json-false nil))
       (json-read-file "lsp-clients.json")))

(defun lsp-doc--client->variables (client)
  ""
  (let ((custom-group (get client 'custom-group)))
    (seq-map
     (apply-partially #'car)
     (seq-filter (lambda (p)
                   (and (consp p)
                        (eq (cadr p) 'custom-variable)))
                 custom-group))))

(defun lsp-doc--decorate-value (key value)
  ""
  (pcase key
    ("installation" (format "`%s`" value))
    ("installation-url" (format "For instruction on how to install, check [here](%s)." value))
    (_ value)))

(defun lsp-doc--replace-placeholders (client)
  ""
  (while (re-search-forward "{{\\([][:word:]\\[.-]+\\)}}" nil t)
    (let* ((key (match-string 1))
           (value (gethash key client)))
      (if value
          (replace-match (lsp-doc--decorate-value key value))
        (replace-match "")))))

(defun lsp-doc--generate-for (client)
  ""
  (-let* (((&hash "name") client)
         (file (file-truename (concat "lsp-" name ".md"))))
    (unless (file-exists-p file)
      (copy-file "template/lsp-client.md" file))
    (with-current-buffer (find-file-noselect file)
      (goto-char (point-min))
      (lsp-doc--replace-placeholders client)
      (save-buffer))))

(defun lsp-doc-generate ()
  "."
  (interactive)
  (seq-doseq (client (lsp-doc--clients))
    (lsp-doc--generate-for client)))

(lsp-doc--generate-for (seq-first (lsp-doc--clients)))

(lsp-doc-generate)

(provide 'lsp-doc)
;;; lsp-doc.el ends here