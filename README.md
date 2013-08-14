![Example:startify in action](https://github.com/mhinz/vim-startify/raw/master/startify.png)

This is it. A start screen for Vim.

What does it provide?
---------------------

It does 3 things that will be explained in detail further below:

* it shows lists of files and directories
* eased session handling
* powerful menu entry handling

#### 1) It shows things on start!

If you start Vim without giving any filenames or piping text to it, Startify
will show a pretty start screen that shows a configurable list of files or
directories:

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

_Please read and understand `:help 'sessionoptions'` if you work with sessions._

Essentially there are two kinds of supported workflows for handling sessions
that will be shown here.

---

__a)__ The Startify way.

The handling of loading, saving and deleting sessions is eased by always
working with one and the same directory. These commands are used for
convenience:

    :SLoad    load a session
    :SSave    save a session
    :SDelete  delete a session

_See `:h startify-commands` for more information._

The advantage of always using the same directory is that Startify can show you a
list of all your sessions that are scattered around the system.

---

__b)__ The old way.

The old way means using `:mksession` to save a `Session.vim` file to the current
directory. Imagine a project folder with a Session.vim at its root directory.
This way makes it very portable.

When Vim gets started and the file Session.vim is found in the current
directory, it will be shown at the top of all lists as entry `[0]` as a
shortcut.

If you bookmark a directory (project folder, anyone?) that contains a
Session.vim, and you access that directory via Startify, that session will be
loaded automatically.

---

Optionally, there is even support for persistent sessions. Thus you load a
session via Startify, add some buffers, remove some buffers, change the window
layout, ..  and when you finish and exit Vim, the session will be saved
automatically. This works for both ways of handling sessions.

_Read `:help startify-options` to learn more about how to configure session
handling to your liking._

#### 3) Powerful entry handling

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

Author & Feedback
-----------------

If you like any of my plugins, please star it on github. That is a great way of
getting feedback. Same for issues reports or feature requests.

---

Marco Hinz _aka_ mhinz _aka_ mhi^ _aka_ mhi

Mail: `<mh.codebro@gmail.com>`

Twitter: [@_mhinz_](https://twitter.com/_mhinz_)

Stackoverflow: [mhinz](http://stackoverflow.com/users/1606959/mhinz)

---

Thank you for flying mhi airlines. Get your Vim on!

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
    :h startify-faq

License
-------

MIT license. Copyright (c) 2013 Marco Hinz.
