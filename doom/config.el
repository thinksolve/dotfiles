
;; ;; -------- LATEX RELATED ---------
;; Override org-latex-preview with math-preview when hitting enter on latex fragment
(defun my/+org/dwim-at-point--math-preview-fix (orig-fn &rest args)
  "Override LaTeX preview handling to use `math-preview` instead of Org's default."
  (let* ((context (org-element-context))
         (type (org-element-type context)))
    (if (memq type '(latex-fragment latex-environment))
        ;; Instead of org-latex-preview, call math-preview
        (math-preview-at-point)
      ;; Fall back to original function
      (apply orig-fn args))))

(advice-add '+org/dwim-at-point :around #'my/+org/dwim-at-point--math-preview-fix)


;; Code below allows fragment to re-render when leaving fragment
(add-hook 'post-command-hook #'my/math-preview-auto-render)


(defun my/math-preview-auto-render ()
  "Auto-render math fragments when cursor leaves them."
  (when (eq major-mode 'org-mode)
    (let* ((current-in-math (my/in-math-fragment-p))
           (current-element (when current-in-math (org-element-context))))
      ;; If we were in math but aren't now, render the previous element
      (when (and my/math-preview-last-element
                 (not current-in-math))
        ;; Clear any lingering selection before rendering
        (my/clear-math-selection)
        (save-excursion
          (goto-char (org-element-property :begin my/math-preview-last-element))
          (math-preview-at-point)))
      ;; Update tracking
      (setq my/math-preview-last-element
            (if current-in-math current-element nil)))))

(defun my/clear-math-selection ()
  "Clear any lingering math fragment selection/highlighting."
  (when (use-region-p)
    (deactivate-mark))
  ;; Clear any math-preview specific overlays that might be causing selection
  (dolist (ov (overlays-at (point)))
    (when (overlay-get ov 'math-preview-selection)
      (delete-overlay ov))))



(defvar my/math-preview-last-element nil
  "Track the last math element we were in.")

(defun my/in-math-fragment-p ()
  "Check if point is in a LaTeX math fragment."
  (let* ((element (org-element-context))
         (type (org-element-type element)))
    (memq type '(latex-fragment latex-environment))))




;; works globally, such as scratch buffer and org-mode
(use-package! math-preview)
(map! :leader
        "m a" #'math-preview-all           ;; Re-render all LaTeX
        "m p" #'math-preview-at-point      ;; Render just at point
        "m c" #'math-preview-clear-all     ;; Clear all previews
)



(use-package! org-preview-html
  :after org
  :commands (org-preview-html-mode)
  :config
  ;; Set MathJax for HTML export
  (setq org-html-mathjax-template
        "<script src=\"https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js\"></script>")
  ;; Set preview viewer
  (setq org-preview-html-viewer 'xwidget) ; or 'eww
  ;; Set refresh configuration
  (setq org-preview-html-refresh-configuration 'manual) ; or 'save', 'export', 'timer', 'instant
  ;; ;; Prevent config reloading (optional perf boost); NOTE: apparently old syntax
  ;;   (setq org-preview-html-refresh-configuration-p nil)
)
;; ;; -------- LATEX RELATED ---------

;; (setq doom-font (font-spec :family "JetBrains Mono" :size 16 :weight 'thin))
(setq doom-font (font-spec :family "JetBrains Mono" :size 16 :weight 'light))

(setq doom-theme
      'tango
      ;; 'leuven
      ;; 'ef-owl
      ;; 'ef-light
      ;; 'ef-day
      ;; 'doom-rouge
      ;; 'doom-moonlight
      ;; 'doom-palenight
      ;; 'doom-tokyo-night
      ;; 'doom-henna
      ;; 'doom-city-lights
      ;; 'doom-one ;;default
)
;; run to disable all themes
;; (mapcar #'disable-theme custom-enabled-themes)


;; NOTE: this works in org-mode but not scratch buffer ..
;; (use-package! math-preview
;;   :after org
;;   (add-hook 'org-mode-hook #'math-preview-all)
;;   :config
;;   (map! :map org-mode-map
;;         :localleader
;;         "a" #'math-preview-all           ;; Re-render all LaTeX
;;
;;         "p" #'math-preview-at-point      ;; Render just at point
;;         "d" #'math-preview-clear-all     ;; Clear all previews
;;         )
;; )
;; (map! "s-<right>" #'my/open-file-in-default-viewer)




;;suppress message when using latex in scratch buffer
;; (setq warning-suppress-types '((org-element org-element-parser)))


;; removes hiding files in dired .. weird default
(remove-hook 'dired-mode-hook #'dired-omit-mode)

(cl-loop for (module . map) in '((doc-view . doc-view-mode-map)
                                 (image . image-mode-map)
                                 (pdf-tools . pdf-view-mode-map)
                                 (archive-mode . archive-mode-map))
         ;; NOTE below: eval-wrapped 'map!' macro needed since loop/dolist evaluates at runtime; macros
         ;; run at macro-time (build time) so cannot interpret _variable_ arguments properly.
         ;; I.e., eval pushes map! to evaluate at runtime.

         do (eval `(map! :after ,module
                         :map ,map
                         :n "<left>" (lambda () (interactive) (kill-current-buffer))))
                         ;; :n "<left>" #'my/kill-and-switch-to-previous-buffer ))
                         ;; :n "<left>" #'my/switch-to-previous-buffer))
)


;; ;; smooth scrolling custom package(.el)
;; (use-package! ultra-scroll
;;   :init
;;   (setq scroll-conservatively 101
;;         scroll-margin 0)
;;   :config
;;   (ultra-scroll-mode 1))


(use-package! drag-stuff
  :config
  (drag-stuff-global-mode 1)
  (drag-stuff-define-keys))  ;; This sets up M-<up>, M-<down>, etc.


;;Lazy-load heavy packages
(use-package lsp-mode
  :defer t
  :hook ((lua-mode nix-mode) . lsp)) ; Load LSP for specific modes

(use-package magit
  :defer t
  :commands (magit-status magit-blame)) ; Load on specific commands

(use-package org
  :defer t
  :commands (org-mode org-agenda)) ; Load when entering Org files or agenda

(use-package vertico
  :defer t
  :init
  (vertico-mode 1) ; Enable Vertico when needed
  :config
  :defer t
  :init
  :config
  (setq dirvish-attributes '(file-size git-msg))) ; Optimize attributes

(use-package corfu
  :defer t
  :init
  (global-corfu-mode 1)) ; Enable Corfu when needed

(use-package orderless
  :defer t
  :init
  (setq completion-styles '(orderless basic))) ; Enable Orderless for completion

;; Performance tweaks
(setq inhibit-compacting-font-caches t) ; Speed up font rendering
(menu-bar-mode -1)                     ; Disable menu bar

;; ==== Enhanced File Navigation ====
;; Global dirvish previews + vertico arrow navigation


;; allows dirvish file previews in (vertico?) minibuffers
(add-hook! 'doom-after-init-hook (dirvish-peek-mode 1))


;; much needed to open a file in default app (like Preview for a pdf ... if i want)
(map! "s-<right>" #'my/open-file-in-default-viewer)
(defun my/open-file-in-default-viewer ()
  "Open the current file in the system's default viewer."
  (interactive)
  (let ((file (if (eq major-mode 'dired-mode)
                  (dired-get-file-for-visit)
                (or (vertico--candidate)
                    (buffer-file-name)))))
    (when file
      (start-process "open-default-viewer" nil "open" (expand-file-name file)))))


;; allows dirvish like navigation within (vertico) minibuffers
(after! vertico
  (define-key vertico-map (kbd "<right>") #'my/vertico-enter-directory)
  (define-key vertico-map (kbd "<left>")  #'my/vertico-up-directory))
  ;; (define-key vertico-map (kbd "s-<right>") #'my/open-file-in-default-viewer))
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




;; s- is the Cmd key in Doom's keymap; this mimics custom OS window switching for emac frames
(map! "s-." #'other-frame)

;; Maximize window when opened normal way (icon click or open command in terminal)
(add-to-list 'initial-frame-alist '(fullscreen . maximized))
;; (add-to-list 'default-frame-alist '(fullscreen . maximized))

;; ;; Maximize window when started via emacsclient
(add-hook 'after-make-frame-functions
          (lambda (frame)
            (select-frame frame)
            (toggle-frame-maximized)))

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

;; _soft_ word wrapping (i.e. no new lines inserted)
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
