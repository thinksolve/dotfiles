

;; ==== Enhanced File Navigation ====
;; Global dirvish previews + vertico arrow navigation

(map! "s-<right>" #'my/open-file-in-default-viewer)


  ;; (define-key vertico-map (kbd "SPC <right>") #'my/open-file-in-default-viewer))
;; (with-eval-after-load 'dired
;;   (define-key dired-mode-map (kbd "SPC <right>") #'my/open-file-in-default-viewer))

(after! vertico
  (define-key vertico-map (kbd "<right>") #'my/vertico-enter-directory)
  (define-key vertico-map (kbd "<left>")  #'my/vertico-up-directory))
  ;; (define-key vertico-map (kbd "s-<right>") #'my/open-file-in-default-viewer))

(add-hook! 'doom-after-init-hook (dirvish-peek-mode 1))

(defun my/open-file-in-default-viewer ()
  "Open the current file in the system's default viewer."
  (interactive)
  (let ((file (if (eq major-mode 'dired-mode)
                  (dired-get-file-for-visit)
                (or (vertico--candidate)
                    (buffer-file-name)))))
    (when file
      (start-process "open-default-viewer" nil "open" (expand-file-name file)))))



(defun my/vertico-enter-directory ()
  "Enter directory or select file in Vertico."
  (interactive)
  (if (and minibuffer-completing-file-name
           (vertico--candidate)
           (file-directory-p (vertico--candidate)))
      (vertico-directory-enter)
    (vertico-exit)))

(defun my/vertico-up-directory ()
  "Go up one directory in Vertico file selection."
  (interactive)
  (when minibuffer-completing-file-name
    (vertico-directory-up)))

;; useful for shell scripting to get emacsclient to open a path within vertico (yazi-like)
(defun my/open-directory-in-vertico (dir)
  "Open DIR in Vertico's find-file minibuffer in the current frame."
  (interactive "DDirectory: ")
  (let ((default-directory (expand-file-name dir)))
    (select-frame-set-input-focus (selected-frame))
    (call-interactively #'find-file)))


;; (defun my/vertico-enter-directory-old ()
;;   "If candidate is a directory, enter it; otherwise, act as RET."
;;   (interactive)
;;   (when minibuffer-completing-file-name
;;     (let* ((input (minibuffer-contents))
;;            (cand (vertico--candidate)))
;;       (cond
;;        ((and cand (file-directory-p cand))
;;         (delete-minibuffer-contents)
;;         (insert (file-name-as-directory cand)))
;;        (t
;;         (vertico-exit))))))

;; (defun my/vertico-up-directory-old ()
;;   "Go up one directory in the minibuffer during file selection."
;;   (interactive)
;;   (when minibuffer-completing-file-name
;;     (let* ((input (minibuffer-contents))
;;            (dir (file-name-directory (directory-file-name (expand-file-name input)))))
;;       (delete-minibuffer-contents)
;;       (insert (file-name-as-directory dir)))))



;; ;; Open Dirvish in your home directory on startup
;; (add-hook! 'emacs-startup-hook
;;   (lambda ()
;;     (unless (or (doom-buffer-list) (minibufferp))
;;       (dirvish "~/" nil))))


;; ;check condig directory (since symlink check with file-truename)
;; (message doom-private-dir)
;; (message (file-truename doom-private-dir))

(setq doom-theme
      'doom-palenight)
      ;; 'doom-moonlight)
      ;; 'doom-city-lights)
      ;; 'doom-one) ;;default

;; (window-divider-mode -1) ;; no longer needed to remove dividing line


(map! "s-." #'other-frame)  ;; s- is the Cmd key in Doom's keymap
;; Maximize window when opened normal way (icon click or open command in terminal)


(add-to-list 'initial-frame-alist '(fullscreen . maximized))
;; (add-to-list 'default-frame-alist '(fullscreen . maximized))

;; ;; Maximize window when started via emacsclient
(add-hook 'after-make-frame-functions
          (lambda (frame)
            (select-frame frame)
            (toggle-frame-maximized)))

;; (setq doom-font (font-spec :family "JetBrains Mono" :size 16 :weight 'thin))
(setq doom-font (font-spec :family "JetBrains Mono" :size 16 :weight 'light))

;; (message "Current font: %s" (face-attribute 'default :font))


;; (add-to-list 'default-frame-alist '(fullscreen . maximized))
;; (setq doom-font (font-spec :size 16)


;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
;; (setq doom-theme 'doom-one)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
;; (setq display-line-numbers t)
(setq display-line-numbers-type 'relative)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.


(global-visual-line-mode 1)


;; (defun my/evil-next-3-lines ()
;;   "Move cursor down 3 lines."
;;   (interactive)
;;   (evil-next-line 3))

;; (defun my/evil-previous-3-lines ()
;;   "Move cursor up 3 lines."
;;   (interactive)
;;   (evil-previous-line 3))

;; (map! :n "j" #'my/evil-next-3-lines
;;       :n "k" #'my/evil-previous-3-lines)

(map! :n "C-j" (cmd! (evil-next-line 3))
      :n "C-k" (cmd! (evil-previous-line 3 )))
