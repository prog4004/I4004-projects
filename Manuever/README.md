Manuever is a 4004 project. The code is from the NPS in Monterey, Ca. This code was originally written by a student of
Garry Kildall. The listing was done on what looks to be a ASR33 teletype. It had poor registration on the print drum.
In many cases, the letter C and number 0 were not destinguishable. This has the source that I've created. It may still have
a few errors. It is at the point that it has a matching number of bytes on each 256 byte page, when assembled. It is
written in my assembler. I am currently using the win32forth version of the assembler and may not work with the FPC version.
Since it is from a listing and my assembler is a single pass, I have created a file that has all the used labels rather than
creating the labels as I go. This file is loaded by the manuever.f source file. 
I've started using my SIM4 simulator on it but not yet finished the instruments.f file for it. This file would have the
attachements that would be the display and keyboard for the manuever project.
