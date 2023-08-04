# AddMainRefs
This repo has an opl/de_opl script to find all complex forms in an SFM file and add missing *\\mn* references to their entries.

## Why run this script
When an sub-entry has its own entry, the FLEx import process needs a pointer (by default a *\\mn* marked field) to the main entry that the sub-entry is under. The *addmainrefs.pl* script looks for all sub-entries under main entries. For each one, if the sub-entry has its own entry, the script will add a pointer field to that entry.

## An Example
Here is an example, "bear trap" from a [Pig Latin](https://en.wikipedia.org/wiki/Pig_Latin) database. "bear trap" is a complex form with its own entry and sub-entries under "bear" and under "trap":

````SFM
\lx earbay
\hm 1
\et Middle English: bere
\sn 1
\ps n
\de a large omnivorous mammal, having shaggy hair
\se earbay raptay

\lx earbay raptay
\ps n
\ge bear trap
\de a large trap used to catch a bear or other mammal, usually as a foot trap

\lx raptay
\ps n
\ge trap
\de A machine or other device designed to catch animals.
\se earbay raptay
````

The script will analyse the SFM file and will find the two sub-entries under "bear" and "trap" and will add \mn entries for them under "bear trap"

````SFM
\lx earbay raptay
\mn earbay
\mn raptay
\ps n
\ge bear trap
\de a large trap used to catch a bear or other mammal, usually as a foot trap
````

## Bugs and Enhancements

1. The FLEx import process doesn't handle sub-entry fields with multiple \mn fields. Additional changes to handle them are not included here.
2. Order the \mn entries -- should be a separate script
