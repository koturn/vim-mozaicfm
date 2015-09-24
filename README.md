vim-mozaicfm
============

[Mozaic.fm](http://mozaic.fm/) client for Vim. Let's enjoy Mozaic.fm with Vim!


## Usage

First, get urls of m4a file and save cache by execute following command.
It takes some time until the command is done.

```vim
:MozaicfmUpdateChannel
```

Second, specify the number you want to listen.

```vim
:MozaicfmPlayByNumber 3
```

#### unite.vim

If you available [unite.vim](https://github.com/Shougo/unite.vim), you may use
the unite source of this Mozaic.fm client.

```vim
:Unite mozaicfm
```

![unite-mozaicfm.png](https://raw.githubusercontent.com/wiki/koturn/vim-mozaicfm/image/unite-mozaicfm.png)

#### ctrlp.vim

You can also use the extension of [ctrlp.vim](https://github.com/ctrlpvim/ctrlp.vim)
if you have installed ctrlp.vim in your Vim.

```vim
:CtrlPMozaicfm
```

![ctrlp-mozaicfm.png](https://raw.githubusercontent.com/wiki/koturn/vim-mozaicfm/image/ctrlp-mozaicfm.png)


## Requirement

- [mplayer](http://www.mplayerhq.hu/design7/news.html)
- HTTP Client (one of the following)
  - python
  - curl
  - wget


## LICENSE

This software is released under the MIT License, see [LICENSE](LICENSE).
