# Introduction

The purpose of *create_pax.sh*  is to create a tar archive with VENDOR specific
keywords in the PAX extended header files using the GNU tar utility.

# Problem

The GNU tar is not directly able to create a tar archive with the VENDOR
specific options. For example, if we want to create an archive with two file,
each file with a vendor specific option to a different value, we would try this:

```console
$ tar -c -v -f archive.tar --format=pax --pax-option "VENDOR.opt:=1" file1 --pax-option "VENDOR.opt:=2" file2
```

Each extended header of the *file1* file will contain the both options
"VENDOR.opt=1" and "VENDOR.opt=2". It is not possible to write an option just
for the next file of the archive.

Note: the *pax* utility in FreeBSD 12.0 refuses to create vendor specifc
options.

# Solution

The script uses a sequence of call to the tar utility. First we create an empty
archive with the global keywords. These options will be written in the first
"g" record of the archive.

```console
$ tar -c -v -f archive.tar --format=pax --pax-option "VENDOR.global=1" -T /dev/null
```

Now, we can add the files in the archive with the corresponding option
keywords. These options will be written in the "x" record preceding each file
record:

```console
$ tar -r -v -f archive.tar --pax-option "VENDOR.opt:=1" file1
$ tar -r -v -f archive.tar --pax-option "VENDOR.opt:=2" file2
```

# create_pax.sh Usage

```console
Usage: ./create_pax.sh ARCHIVE VENDOR_IDENTIFIER < INI_FILE
Example: ./create_pax.sh archive.tar VENDOR < conf.ini
```

The INI file taken on standard input is a INI configuration wile with section
*[global]* describing the global options. And for each file a *[file]* section
with a mandatory*pathname* property and the corresponding file options.

```console
$ create_pax.sh archive.tar "VENDOR" <<EOF
[global]
global=1

[file]
pathname=file1
opt=1

[file]
pathname=file2
opt=2
EOF
```