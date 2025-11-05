return {
	"sainnhe/everforest",
	config = function()
		vim.cmd([[
    if has('termguicolors')
      set termguicolors
    endif

    set background=dark
  " set background=light
    let g:everforest_background = 'hard'
    let g:everforest_better_performace = 1
    colorscheme everforest
  ]])
	end,
}
