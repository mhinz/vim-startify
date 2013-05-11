vim-startify
------------

Startify basically provides two things:

_1)_ If you start Vim without giving any filenames to it (or pipe stuff to it so
   it reads from STDIN), startify will show a small but pretty start screen
   which shows recently used files (using viminfo) and sessions by default.

   Additionally, you can define bookmarks, thus entries for files that always
   should be available in the start screen.

   You can either navigate to a certain menu entry or you just key in whatever
   is written between the square brackets on that line. You can even
   double-click anywhere on the line now.

   Per default the startify buffer gets closed automatically, if an entry was
   selected.

   You can reopen the screen via :Startify.

   Moreover, 'e' creates an empty buffer, 'i' creates an empty buffers and
   jumps into insert mode, 'q' quits.

_2)_ It eases handling of loading and saving sessions by only working with a
   certain directory. These commands are used for convenience:

      :SLoad    load a session
      :SSave    save a session
      :SDelete  delete a session

_NOTE_: Both commands can also take session names directly as an argument. You can
also make use of completion via `<c-u>` and `<tab>`.

The default settings are pretty sane, so it should work without any
configuration.

![Example:startify in action](https://github.com/mhinz/vim-startify/raw/master/startify.png)

_NOTE_: The colors shown in the screenshot are not the default. If you want to
tune the default colors, you can overwrite the highlight groups used by startify
in your vimrc. Have a look at `:h startify-colors`, after installing the plugin.
Moreover, g:startify_enable_special is set to 0.

Feedback, please!
-----------------

If you like any of my plugins, star it on github. This is a great way of getting
feedback! Same for issues or feature requests.

Thank you for flying mhi airlines. Get the Vim on!

Installation
------------

If you have no preferred installation method, I suggest using tpope's pathogen:

1. git clone https://github.com/tpope/vim-pathogen ~/.vim/bundle/vim-pathogen
1. mkdir -p ~/.vim/autoload && cd ~/.vim/autoload
1. ln -s ../bundle/vim-pathogen/autoload/pathogen.vim

Afterwards installing vim-startify is as easy as pie:

2. git clone https://github.com/mhinz/vim-startify ~/.vim/bundle/vim-startify
2. start Vim
2. :Helptags
2. :h startify

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
