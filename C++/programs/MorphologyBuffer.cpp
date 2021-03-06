////////////////////////////////////////////////////////////////////////////////
//! @file	: MorphologyBuffer.cpp
//! @date   : Jul 2013
//!
//! @brief  : Morphological operations on image buffers
//! 
//! Copyright (C) 2013 - CRVI
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

#include "Programs/MorphologyBuffer.h"


#define KERNEL_RANGE(src_img) GetRange(src_img, UseLocalRange(Width)), GetLocalRange(UseLocalRange(Width))
#define SELECT_NAME(name, src_img) SelectName( #name , Width)

#include "kernel_helpers.h"

#include "WorkGroup.h"


namespace OpenCLIPP
{

static bool UseLocalRange(int /*Width*/)
{
   // We never use the local version - it seems to be slower than the simple version
   return false;
}

static std::string SelectName(const char * Name, int Width)  // Selects the proper kernel name
{
   std::string KernelName = Name;
   KernelName += std::to_string(Width);

   if (UseLocalRange(Width))
      KernelName += "_cached";

   return KernelName;
}


void MorphologyBuffer::Erode(ImageBuffer& Source, ImageBuffer& Dest, int Width)
{
   CheckCompatibility(Source, Dest);

   if ((Width & 1) == 0)
      throw cl::Error(CL_INVALID_ARG_VALUE, "Width for morphology operations must be impair");

   if (Width < 3 || Width > 63)
      throw cl::Error(CL_INVALID_ARG_VALUE, "Width for morphology operations must >= 3 && <= 63");

   Kernel(erode, Source, Dest, Source.Step(), Dest.Step(), Source.Width(), Source.Height());
}

void MorphologyBuffer::Dilate(ImageBuffer& Source, ImageBuffer& Dest, int Width)
{
   CheckCompatibility(Source, Dest);

   if ((Width & 1) == 0)
      throw cl::Error(CL_INVALID_ARG_VALUE, "Width for morphology operations must be impair");

   if (Width < 3 || Width > 63)
      throw cl::Error(CL_INVALID_ARG_VALUE, "Width for morphology operations must >= 3 && <= 63");

   Kernel(dilate, Source, Dest, Source.Step(), Dest.Step(), Source.Width(), Source.Height());
}

void MorphologyBuffer::Erode(ImageBuffer& Source, ImageBuffer& Dest, ImageBuffer& Temp, int Iterations, int Width)
{
   if (Iterations <= 0)
      return;

   bool Pair = ((Iterations & 1) == 0);

   if (Pair)
   {
      Erode(Source, Temp, Width);
      Erode(Temp, Dest, Width);
   }
   else
      Erode(Source, Dest, Width);

   for (int i = 2; i < Iterations; i += 2)
   {
      Erode(Dest, Temp, Width);
      Erode(Temp, Dest, Width);
   }

}

void MorphologyBuffer::Dilate(ImageBuffer& Source, ImageBuffer& Dest, ImageBuffer& Temp, int Iterations, int Width)
{
   if (Iterations <= 0)
      return;

   bool Pair = ((Iterations & 1) == 0);

   if (Pair)
   {
      Dilate(Source, Temp, Width);
      Dilate(Temp, Dest, Width);
   }
   else
      Dilate(Source, Dest, Width);

   for (int i = 2; i < Iterations; i += 2)
   {
      Dilate(Dest, Temp, Width);
      Dilate(Temp, Dest, Width);
   }

}

void MorphologyBuffer::Open(ImageBuffer& Source, ImageBuffer& Dest, ImageBuffer& Temp, int Depth, int Width)
{
   Erode(Source, Temp, Dest, Depth, Width);
   Dilate(Temp, Dest, Temp, Depth, Width);
}

void MorphologyBuffer::Close(ImageBuffer& Source, ImageBuffer& Dest, ImageBuffer& Temp, int Depth, int Width)
{
   Dilate(Source, Temp, Dest, Depth, Width);
   Erode(Temp, Dest, Temp, Depth, Width);
}

void MorphologyBuffer::TopHat(ImageBuffer& Source, ImageBuffer& Dest, ImageBuffer& Temp, int Depth, int Width)
{
   Open(Source, Temp, Dest, Depth, Width);
   m_Arithmetic.Sub(Source, Temp, Dest);     // Source - Open
}

void MorphologyBuffer::BlackHat(ImageBuffer& Source, ImageBuffer& Dest, ImageBuffer& Temp, int Depth, int Width)
{
   Close(Source, Temp, Dest, Depth, Width);
   m_Arithmetic.Sub(Temp, Source, Dest);     // Close - Source
}

void MorphologyBuffer::Gradient(ImageBuffer& Source, ImageBuffer& Dest, ImageBuffer& Temp, int Width)
{
   Erode(Source, Temp, Width);
   Dilate(Source, Dest, Width);
   m_Arithmetic.Sub(Dest, Temp, Dest);     // Dilate - Erode
}

}
