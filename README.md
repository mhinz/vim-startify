![Example:startify in action](https://github.com/mhinz/vim-startify/raw/master/startify.png)

This is it. A splash screen for Vim.

What does it provide?
---------------------

__1)__ If you start Vim without giving any filenames to it (or pipe stuff to it
   so it reads from STDIN), startify will show a small but pretty start screen
   that shows recently used files (using viminfo) and sessions by default.

   Additionally, you can define bookmarks, thus entries for files that always
   should be available on the start screen.

   You can either navigate to a certain menu entry and hit enter or you just
   key in whatever is written between the square brackets on that line. You
   can even double-click anywhere on the line now.

   In addition, `e` creates an empty buffer, `i` creates an empty buffer and
   jumps into insert mode, `q` quits.

   Moreover, you can open several files at one go. Navigate to an entry and
   hit either `b` (open in same window), `s` (open in split) or `v` (open in
   vertical split). You can do that for multiple entries. You can also mix
   them. The order of the selections will be remembered. Afterwards execute
   these actions via `<cr>`.

   When the selection is finished, Startify will close automatically. You can
   reopen the screen via `:Startify`.

   And you can define your own custom ascii art header now!

__2)__ It eases handling of loading and saving sessions by only working with a
   certain directory. These commands are used for convenience:

      :SLoad    load a session
      :SSave    save a session
      :SDelete  delete a session

__NOTE__: These commands can also take session names directly as an argument.
You can also make use of completion via `<c-d>` and `<tab>`.

Feedback, please!
-----------------

If you like any of my plugins, star it on github. This is a great way of getting
feedback! Same for issues or feature requests.

Thank you for flying mhi airlines. Get the Vim on!

Installation
------------

If you have no preferred installation method, I suggest using tpope's pathogen:

    $ git clone https://github.com/tpope/vim-pathogen ~/.vim/bundle/vim-pathogen
    $ mkdir -p ~/.vim/autoload && cd ~/.vim/autoload
    $ ln -s ../bundle/vim-pathogen/autoload/pathogen.vim

Afterwards installing vim-startify is as easy as pie:

    $ git clone https://github.com/mhinz/vim-startify ~/.vim/bundle/vim-startify
    $ start Vim
    $ :Helptags
    $ :h startify

It works without any configuration, but you might want to look into the
documentation for further customization.

Documentation
-------------

`:h startify`

Author
------

Marco Hinz `<mh.codebro@gmail.com>`

License
-------

Copyright © Marco Hinz. Distributed under the same terms as Vim itself. See
`:help license`.
