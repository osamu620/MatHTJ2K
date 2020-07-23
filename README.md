MatHTJ2K
=====

MatHTJ2K is an implementation of JPEG 2000 Part 1 and Part 15 as defined in Rec. ITU-T T.800 | ISO/IEC 15444-1 and Rec. ITU-T T.814 | ISO/IEC 15444-15, written in MATLAB language.

## Description 

High Throughput JPEG 2000 (HTJ2K) is a new part of JPEG 2000 standard. The purpose of MatHTJ2K is to help a person who wants to develop an HTJ2K-based image compression system to understand the algorithms defined in HTJ2K. 

What you can do with MatHTJ2K are:

- to compress an image into a codestream which is compliant with JPEG 2000 Part 1 or Part 15.
- to decompress a codestream which is compliant with JPEG 2000 Part 1 or Part 15 into an image.
- to read/to write .jp2 and .jph file.

## Prerequisites

- MATLAB 2018b or higher with Image processing toolbox (older version may be fine, but not tested.)
  - to use MEX version of block-coder, MATLAB Coder is required.

## Install

Type the following command in the command window:

`addpath(genpath('source'))`

If you want to save path settings for future session, use `savepath` command.

## Usage

### MEX functions (optional)

To generate MEX functions, type `generate_MEX_files` in the command window.

### Encoding

To compress an image stored in array "IMG", type the following command in the command window:

`encode_HTJ2K(filename, IMG, MEXflag)`

`MEXflag` should be `true` if you want to use MEX version of  block-coder.

#### available options to encoder

 please see help (type `help encode_HTJ2K` in the command window)

### Decoding

To decompress a codestream, jp2 or jph, type the following command in the command window:

`[output composited_output] = decode_HTJ2K(filename, MEXflag, reduce_NL)`

`MEXflag` should be `true` if you want to use MEX version of  block-coder.

`reduce_NL` is number of DWT resolution to be reduced from that of the original codestream/file. 

For further details, please see help encode_HTJ2K/decode_HTJ2K.

## Author

- Osamu Watanabe

## Citation

Please cite [this](https://doi.org/10.1109/GCCE46687.2019.9015602) paper if you use MatHTJ2K for your published work.

> O. Watanabe and D. Taubman, "A Matlab Implementation of the Emerging HTJ2K Standard," 2019 IEEE 8th Global Conference on Consumer Electronics (GCCE), Osaka, Japan, 2019, pp. 491-495, doi: 10.1109/GCCE46687.2019.9015602.

## License

The copyright in this software is being made available under the License, included below. This software may be subject to other third party and contributor rights, including patent rights, and no such rights are granted under this license.

Copyright (c) 2018-2020, Osamu Watanabe
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice,this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of ISO nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.