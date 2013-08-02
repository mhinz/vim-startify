![Example:startify in action](https://github.com/mhinz/vim-startify/raw/master/startify.png)

This is it. A start screen for Vim.

What does it provide?
---------------------

#### 1) It shows things on start!

If you start Vim without giving any filenames or piping text to it, Startify
will show a pretty start screen that shows a configurable list of items:

---

__Custom header__ ( _empty by default_ ):

How about some ASCII art action?

---

__Files from directory__ ( _disabled by default_ ):

This lists all files from the current directory sorted by modification time.

---

__Recently used files__ ( _enabled by default_ ):

This uses the viminfo file to get a list of most recently used files. The list
can also be filtered.

---

__Sessions__ ( _enabled by default_ ):

This will list all your sessions from a certain directory.

---

__Bookmarks__ ( _empty by default_ ):

Additionally, you can define bookmarks, thus entries for files that always
should be available on the start screen.

---

See `:h startify-options` for more information.

#### 2) Easy session handling

It eases handling of loading, saving and deleting sessions by always working
with one and the same directory. These commands are used for convenience:

    :SLoad    load a session
    :SSave    save a session
    :SDelete  delete a session

See `:h startify-commands` for more information.

#### 3) Easy but powerful entry handling

You can either navigate to a certain entry using `j`/`k` and hit `<cr>` or just
key in whatever is written between the square brackets on that line. You can
even double-click anywhere on the line.

Moreover, you can open several files at one go! Navigate to an entry and hit
either `b` (open in same window), `s` (open in split) or `v` (open in vertical
split) for marking it. You can mark several entries and also mix different
markers. Afterwards execute all the markers in the order they were given via
`<cr>`.

In case you don't want to open a file, there is also `e` for creating an empty
buffer, `i` for creating an empty buffer and jumping into insert mode and `q`
for quitting.

When one or more files were opened by Startify, it will close automatically. You
can always reopen the screen via `:Startify`.

Feedback, please!
-----------------

If you like any of my plugins, star it on github. This is a great way of getting
feedback! Same for issues or feature requests.

Thank you for flying mhi airlines. Get your Vim on!

You can also follow me on Twitter: [@_mhinz_](https://twitter.com/_mhinz_)

Installation & Documentation
----------------------------

If you have no preferred installation method, I suggest using tpope's
[pathogen](https://github.com/tpope/vim-pathogen). Afterwards installing
vim-startify is as easy as pie:

    $ git clone https://github.com/mhinz/vim-startify ~/.vim/bundle/vim-startify
    $ vim

It works without any configuration, but you might want to look into the
documentation for further customization:

    :Helptags  " rebuilding tags files
    :h startify

Author
------

Marco Hinz `<mh.codebro@gmail.com>`

License
-------

MIT license. Copyright (c) 2013 Marco Hinz.
