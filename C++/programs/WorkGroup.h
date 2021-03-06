////////////////////////////////////////////////////////////////////////////////
//! @file	: WorkGroup.h
//! @date   : Jan 2014
//!
//! @brief  : Tools to handle kernels that use a specific workgroup size
//! 
//! Copyright (C) 2014 - CRVI
//!
//! This file is part of OpenCLIPP.
//! 
//! OpenCLIPP is free software: you can redistribute it and/or modify
//! it under the terms of the GNU Lesser General Public License version 3
//! as published by the Free Software Foundation.
//! 
//! OpenCLIPP is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU Lesser General Public License for more details.
//! 
//! You should have received a copy of the GNU Lesser General Public License
//! along with OpenCLIPP.  If not, see <http://www.gnu.org/licenses/>.
//! 
////////////////////////////////////////////////////////////////////////////////


// Local group & global group logic :
//  In OpenCL, computation tasks are split in workitems
//  The number of workitems is given by the global range
//  Workitems are grouped by Workgroups
//  Some algorithms (like local caching & reductions) use workgroups of a fixed size for specific optimization (local memory usage & sychronization)
//  Example workgroup sizes are 16x16 and 32x32
//  When working with a specific local size (workgroup size), the global range (number of workitems) must be a multiple of the local size
//  This file presents a few functions to help using a local range

#ifndef PIXELS_PER_WORKITEM
#define PIXELS_PER_WORKITEM   1
#endif

#ifndef LOCAL_SIZE
#define LOCAL_SIZE 16
#endif

// Disable warning about unused static functions
// We need these functions to be static because they use these static global variables
// But not every .cpp file that uses this .h file uses all the functions so we get unused static functions, which flags a warning
#ifdef _MSC_VER
#pragma warning ( disable : 4505 )
#else
#pragma GCC diagnostic ignored "-Wunused-function"
#endif


namespace OpenCLIPP
{

const static int GroupWidth = LOCAL_SIZE;                      // Width of a workgroup8
const static int GroupHeight = LOCAL_SIZE;                     // Height of a workgroup
const static int PixelsPerWorker = PIXELS_PER_WORKITEM;        // Number of pixels processed per workitem
const static int GroupPxWidth = GroupWidth * PixelsPerWorker;  // Number of pixels that 1 workgroup will process one 1 row

static bool FlushWidth(const ImageBase& Image);      // Is Width a multiple of GroupWidth*PixelsPerWorker
static bool FlushHeight(const ImageBase& Image);     // Is Height a multiple of GroupHeight
static bool IsFlushImage(const ImageBase& Image);    // Are both Width and Height flush

static uint GetNbWorkersW(const ImageBase& Image);   // Number of work items to be launched for each row of the image, including inactive work items
static uint GetNbWorkersH(const ImageBase& Image);   // Number of work items to be launched for each column of the image, including inactive work items

static uint GetNbGroupsW(const ImageBase& Image);    // Number of work groups along X
static uint GetNbGroupsH(const ImageBase& Image);    // Number of work groups along Y

static cl::NDRange GetRange(const ImageBase& Image, bool UseLocalSize = true);   // Global range for the image - GetNbWorkersW() * GetNbWorkersH()
static cl::NDRange GetLocalRange(bool UseLocalSize = true);                      // Local range - GroupWidth * GroupHeight

static uint GetNbGroups(const ImageBase& Image);     // Number of work groups for the image - GetNbGroupsW() * GetNbGroupsH()


static bool FlushWidth(const ImageBase& Image)
{
   if (Image.Width() % GroupPxWidth > 0)
      return false;

   return true;
}

static bool FlushHeight(const ImageBase& Image)
{
   if (Image.Height() % GroupHeight > 0)
      return false;

   return true;
}

static bool IsFlushImage(const ImageBase& Image)
{
   return FlushWidth(Image) && FlushHeight(Image);
}

static uint GetNbWorkersW(const ImageBase& Image)
{
   uint Nb = Image.Width() / GroupPxWidth * GroupWidth;
   if (!FlushWidth(Image))
      Nb += GroupWidth;

   return Nb;
}

static uint GetNbWorkersH(const ImageBase& Image)
{
   uint Nb = Image.Height() / GroupHeight * GroupHeight;
   if (!FlushHeight(Image))
      Nb += GroupHeight;

   return Nb;
}

static uint GetNbGroupsW(const ImageBase& Image)
{
   return GetNbWorkersW(Image) / GroupWidth;
}

static uint GetNbGroupsH(const ImageBase& Image)
{
   return GetNbWorkersH(Image) / GroupHeight;
}

static cl::NDRange GetRange(const ImageBase& Image, bool UseLocalSize)
{
   if (UseLocalSize)
      return cl::NDRange(GetNbWorkersW(Image), GetNbWorkersH(Image), 1);

   return cl::NDRange(Image.Width() / PixelsPerWorker, Image.Height(), 1);
}

static cl::NDRange GetLocalRange(bool UseLocalSize)
{
   if (UseLocalSize)
      return cl::NDRange(GroupWidth, GroupWidth, 1);

   return cl::NullRange;
}

static uint GetNbGroups(const ImageBase& Image)
{
   return GetNbGroupsW(Image) * GetNbGroupsH(Image);
}

}
