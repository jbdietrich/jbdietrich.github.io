# Running `barf` on MacOS

2023-01-18

The `barf` project was built on Linux and was catered towards Linux users. The core of the project will remain focused on Linux/GNU tools, but that doesn't mean MacOS needs to be left out in the cold.

There are some very minor changes you'll need to make to your default `sed` and `date` paths if you plan to run barf on MacOS.

## Download Packages

This walkthrough assumes that you already have [homebrew](https://brew.sh/) installed on your machine.

You will need to install the GNU versions of both `date` and `sed` in order to avoid breaking things when `barf` tries to build.


    brew install coreutils
    brew install gnu-sed


## Setting `gsed` and `gdate` as Default

Now run the following in a terminal shell:

    sudo ln -fs /opt/homebrew/bin/gsed /usr/local/bin/sed
    sudo ln -fs /opt/homebrew/bin/gdate /usr/local/bin/date

and add the following to your `.bash_profile` file:

    export PATH="/usr/local/bin:$PATH"

Reload your `bash` instance and everything should work as intended!
