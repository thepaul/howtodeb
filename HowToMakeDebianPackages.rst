===========================
How To Make Debian Packages
===========================

.. meta::
   :description: Manual/Howto for creaging and maintaining Debian packages
   :keywords: deb, debhelper, debian package, debian/rules, cdbs
   :author: paul cannon <pik@debian.org>
   :license: Contents released under the terms of the MIT/X11 license.

It's so easy!

.. contents::

------------
Introduction
------------

While every detail about the creation, building, and maintenance of Debian
packages can be found on the Internet, there does not appear to be any one
document or website presenting all of that information in any sort of
organized manner. Possibly because of this, package-building is often
considered an arcane, difficult art. Distributors of software-- even software
intended mainly for use on Debian-based systems-- too frequently elect to
provide their software in a bare tarball, as a self-executable, or otherwise
attempt to reinvent modern packaging systems.

This unfortunate because it is not really that difficult to create packages,
and because packages add tremendous value to the end user. Hopefully some
distributors of software-- whether they are providing a clever 15-line shell
script or a twenty-gigabyte behemoth of a desktop app-- will find it easier to
learn the details of good packaging.

-----------------
About this manual
-----------------

.. note::
   For the impatient, the section "`Turbo Quick Start`_" should give you what
   you need to immediately start creating your package, without all the other
   explanation and background.

This manual is intended to bring together all the most important information
one needs to know in order to create and maintain Debian packages. Where it
does not delve in to the lowest-level details, it should refer the reader to
websites or publications where those details can be found.

The reader is expected to be only mildly familiar with GNU/Linux in general; a
working knowledge of Makefiles, tar, and basic Bourne shell usage is presumed.

The rationale behind packaging systems will be discussed, followed by an
overview of Debian packages in particular and how they differ from other
packaging systems.

Following that groundwork, Debian packages will be explained from the "ground
up". An existing .deb file will be dissected and the technical basic structure
of a Debian binary package laid out. Then the focus will be moved to tools and
practices that ease the creation of that structure: starting from the
lower-level tools and proceeding up to CDBS, which the author considers to be
the most advanced Debian-package creation tool currently available.

---------------------
Why package software?
---------------------

.. or "what should packaging do for you"- simple distribution, dependencies,
   clean uninstall, simple upgrades, ..?

------------------------
Your goals as a packager
------------------------

.. clean install/uninstall, configuration automatability

---------------------------------
What exactly are Debian packages?
---------------------------------

.. meaning of "debs"
.. binary/source pkgs, metadata associated(?), dpkg tool
.. compare/contrast with rpm, tgz

---------------------------------
Nuts and bolts of binary packages
---------------------------------

To understand a Debian package, it may be helpful to understand what it is
at the most basic level. It is not necessary to remember all of these "nuts
and bolts" details in order to build a good package, but reading the section
may help understand the purposes of the tools discussed later.

First, let's find out what a Debian binary package consists of. A .deb is a
specialized archive [#ar-archive]_, rather like a .zip or .tar file, but with
some extra metainfo. It can be built and extracted and queried using the
``dpkg-deb`` tool.

As an example, we here extract the contents of the openssh-server package,
version 1:4.3p2-3~bpo.1 as distributed by backports.org.

::
  knuth:~/work/tmp$ dpkg-deb -x openssh-server_1%3a4.3p2-3~bpo.1_i386.deb pkg-insides
  knuth:~/work/tmp$ ls -l pkg-insides

Filesystem 
============

The plain filesystem-y contents of the package can be found in data.tar.gz. At
a certain point in a Debian package installation, all those files will be
moved into the root filesystem exactly as they appear in the ``data.tar.gz``
(a few considerations apply for "conffiles" and to avoid overwriting other
packages' files)::

  knuth:~/work/tmp paul$ tar xvzf data.tar.gz 
  ./
  ./etc/
  ./etc/init.d/
  ./etc/init.d/ssh
  ./etc/default/
  ./etc/default/ssh
  ./etc/pam.d/
  ./etc/pam.d/ssh
  ./usr/
  ./usr/lib/
  ./usr/lib/openssh/
  ./usr/lib/openssh/sftp-server
  ./usr/sbin/
  ./usr/sbin/sshd
  ./usr/share/
  ./usr/share/man/
  ./usr/share/man/man5/
  ./usr/share/man/man5/sshd_config.5.gz
  ./usr/share/man/man8/
  ./usr/share/man/man8/sshd.8.gz
  ./usr/share/man/man8/sftp-server.8.gz
  ./usr/share/doc/
  ./usr/share/doc/openssh-client/
  ./var/
  ./var/run/
  ./var/run/sshd/
  ./usr/lib/sftp-server
  ./usr/share/doc/openssh-server

Control tarball
===============

The control tarball, then, as you might expect, contains the metadata about
the package::

  knuth:~/work/tmp paul$ tar xvzf control.tar.gz 
  ./
  ./config
  ./templates
  ./postinst
  ./preinst
  ./prerm
  ./postrm
  ./conffiles
  ./md5sums
  ./control

Only a few of those are required, and there are a few other files that could
appear here.  We'll just look briefly at the ones from the openssh-server
package:

* ``config`` is a script. If present, it can be used by "Debconf" (Debian's
  central package-configuration management system) to prompt for and collect
  configuration values.

* ``templates``, if present, contains internationalized strings for all
  Debconf text.

* ``preinst`` is a script. If present, it takes care of package setup that
  needs to be done *before* the package's files are unpacked into the
  filesystem.

* ``postinst`` is a script. If present, it takes care of package setup that
  needs to be done *after* the package's files are unpacked into the
  filesystem.

* ``prerm`` is a script. If present, it takes care of package teardown that
  needs to be done *before* the package's files are removed from the
  filesystem.

* ``postrm`` is a script. If present, it takes care of package cleanup that
  needs to be done *after* the package's files are removed from the
  filesystem.

* ``conffiles`` lists the files from ``data.tar.gz`` which should be treated
  as configuration files. This is practically always the same as "all files
  that go under ``/etc``".

* ``md5sums`` is exactly that; an "``md5sum -c``"-friendly list of the md5sums
  of the files in the package.

* ``control`` is the package control file. It informs Debian what the package
  name is, what its dependencies and conflicts are, and contains the package
  description, current version, and other organizational metainfo.

So that's it. That's technically all there is to a Debian package. If you
like, you can handcraft that filesystem organization and assemble those
control files using nothing but a shell and a text editor, tar up a
``control.tar.gz`` and a ``data.tar.gz``, and roll them into an ``ar`` archive
with a ``debian-binary`` file -- you'll have a debian package!

So why use tools in this process, when you can already do the job and the
tools require more learning and practice? There are three reasons:

* The tools make the packaging process faster, especially when you'll be
  building multiple versions.

* The tools can catch a lot of errors and bugs that you might not otherwise
  notice until your package is installed and breaks horribly.

* The tools can help ensure that your package conforms to best practices and
  `Debian Policy`_. You might not care about that, especially if your package
  is not going to be an official Debian package, but it matters: if your
  package does not play well with others, you could break other things in a
  system besides the working of your own package.

Building packages by hand is not at all recommended.

---------------------------------
Nuts and bolts of source packages
---------------------------------

The lowest-level way to maintain a package is to keep a set of
packaging-specific files in a directory called "``debian``" under the top
level of the source tree. There are a few files that you must have there:

* ``debian/changelog``
* ``debian/control``
* ``debian/rules``

------------------------
Details of control files
------------------------

---------
Debhelper
---------

The most common toolset used to ease Debian packaging is called Debhelper_.
Debhelper.  It consists of a series of command-line utilities that automate
nearly all of the common tasks that would otherwise need to be coded over and
over (most likely introducing countless different bugs in different places).

Debhelper utilities are also kept up-to-date with `Debian Policy`_ changes, so
that packages created with Debhelper are much more likely to be valid still in
the face of such changes than would a hand-coded package.

All Debhelper utilities have the prefix "``dh_``".

----
CDBS
----

.. Build-Depends
.. include /usr/share/cdbs/1/rules/debhelper.mk

.. debhelper/make targets addable-
.. build/$PACKAGENAME
.. binary-install/$PACKAGENAME
.. cleanbuilddir/$PACKAGENAME
.. clean

.. vars- DEB_DH_ALWAYS_EXCLUDE, DEB_DH_INSTALLINIT_ARGS, etc

.. python distutils (include /usr/share/cdbs/1/class/python-distutils.mk)

--------------------
_`Turbo Quick Start`
--------------------

.. dh_make or a similar script? i'm not a big dh_make fan. internal/external
   links to any details of interest.


.. Links

.. _Debian: http://www.debian.org/
.. _Debian Policy: http://www.debian.org/doc/debian-policy/
.. _Debhelper: _http://www.fifi.org/cgi-bin/man2html/usr/share/man/man1/debhelper.1.gz

.. Footnotes

.. [#ar-archive]
   The outermost shell of the internal .deb format is very similar to that of
   an ``ar`` archive [#about-ar-archives]_. In fact, you can use the ``ar``
   tool to extract that layer::

     knuth:~/work/tmp paul$ ls -l
     total 216
     -rw-r--r--    1 paul     paul       217488 Jun 11 15:29 openssh-server_1%3a4.3p2-3~bpo.1_i386.deb
     knuth:~/work/tmp paul$ ar x openssh-server_1%3a4.3p2-3~bpo.1_i386.deb 
     knuth:~/work/tmp paul$ ls -l
     total 436
     -rw-r--r--    1 paul     paul        27657 Jun 11 15:29 control.tar.gz
     -rw-r--r--    1 paul     paul       189638 Jun 11 15:29 data.tar.gz
     -rw-r--r--    1 paul     paul            4 Jun 11 15:29 debian-binary
     -rw-r--r--    1 paul     paul       217488 Jun 11 15:29 openssh-server_1%3a4.3p2-3~bpo.1_i386.deb
     knuth:~/work/tmp paul$ cat debian-binary 
     2.0

   The ``data.tar.gz`` contains the filesystem hierarchy portion of the package,
   and the ``control.tar.gz`` contains what will go in the ``DEBIAN`` metainfo
   area. The ``debian-binary`` file contains a package version number; as of
   this writing, it should be surprising to see anything besides "``2.0``".

   The fact that you can unpack .debs with ``ar`` has given rise to the common
   misconception that .debs *are* ``ar`` archives. That's not quite the case;
   you can unpack a .deb with ``ar``, but you can not *create* a valid .deb
   with it.

.. [#about-ar-archives]
   This is a type of archive similar to that made by ``tar``. It is typically
   used for ``.a`` library files in Unices. See the `Wikipedia explanation
   <http://en.wikipedia.org/wiki/Ar_(Unix)>`_, the `man page
   <http://linux.die.net/man/1/ar>`_, and `the Open Group reference spec
   <http://www.opengroup.org/onlinepubs/009695399/utilities/ar.html>`_ for
   ``ar``.
