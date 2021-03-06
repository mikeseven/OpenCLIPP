////////////////////////////////////////////////////////////////////////////////
//! @file	: Filters.cl
//! @date   : Jul 2013
//!
//! @brief  : Convolution-style filters on images
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


constant sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_NEAREST;

#ifdef I

   // For signed integer images
   #define READ_IMAGE(img, pos) convert_float4(read_imagei(img, sampler, pos))
   #define WRITE_IMAGE(img, pos, px) write_imagei(img, pos, convert_int4_sat(px))
   #define TYPE int4

#else // I

   #ifdef UI

      // For unsigned integer images
      #define READ_IMAGE(img, pos) convert_float4(read_imageui(img, sampler, pos))
      #define WRITE_IMAGE(img, pos, px) write_imageui(img, pos, convert_uint4_sat(px))
      #define TYPE uint4

   #else // UI

      // For float
      #define READ_IMAGE(img, pos) read_imagef(img, sampler, pos)
      #define WRITE_IMAGE(img, pos, px) write_imagef(img, pos, px)
      #define TYPE float4

   #endif // UI

#endif // I

#ifdef __NV_CL_C_VERSION
#define NVIDIA_PLATFORM
#endif

#ifdef _AMD_OPENCL
#define AMD_PLATFORM
#endif

#ifdef NVIDIA_PLATFORM
   #define CONST static constant const
   #define CONST_ARG constant const
#else
   #ifdef AMD_PLATFORM
      #define CONST const
      #define CONST_ARG const
   #else
      #define CONST constant const
      #define CONST_ARG constant const
   #endif
#endif


#define BEGIN \
   const int gx = get_global_id(0);\
   const int gy = get_global_id(1);\
   const int2 pos = { gx, gy };


#define CONVOLUTION_CASE(size)\
   case size:\
   {\
      for (int y = -size; y <= size; y++)\
         for (int x = -size; x <= size; x++)\
            sum += matrix[Index++] * READ_IMAGE(source, pos + (int2)(x, y));\
   }\
   break;

#define CONVOLUTION_SWITCH\
   switch(mask_size)\
   {\
   CONVOLUTION_CASE(1) /* 3x3*/\
   CONVOLUTION_CASE(2) /* 5x5*/\
   CONVOLUTION_CASE(3) /* 7x7*/\
   CONVOLUTION_CASE(4) /* 9x9*/\
   CONVOLUTION_CASE(5) /* 11x11*/\
   CONVOLUTION_CASE(6) /* 13x13*/\
   CONVOLUTION_CASE(7) /* 15*/\
   CONVOLUTION_CASE(8) /* 17*/\
   CONVOLUTION_CASE(9) /* 19*/\
   CONVOLUTION_CASE(10) /* 21*/\
   CONVOLUTION_CASE(11) /* 23*/\
   CONVOLUTION_CASE(12) /* 25*/\
   CONVOLUTION_CASE(13) /* 27*/\
   CONVOLUTION_CASE(14) /* 29*/\
   CONVOLUTION_CASE(15) /* 31*/\
   CONVOLUTION_CASE(16) /* 33*/\
   CONVOLUTION_CASE(17) /* 35*/\
   CONVOLUTION_CASE(18) /* 37*/\
   CONVOLUTION_CASE(19) /* 39*/\
   CONVOLUTION_CASE(20) /* 41*/\
   CONVOLUTION_CASE(21) /* 43*/\
   CONVOLUTION_CASE(22) /* 45*/\
   CONVOLUTION_CASE(23) /* 47*/\
   CONVOLUTION_CASE(24) /* 49*/\
   CONVOLUTION_CASE(25) /* 51*/\
   CONVOLUTION_CASE(26) /* 53*/\
   CONVOLUTION_CASE(27) /* 55*/\
   CONVOLUTION_CASE(28) /* 57*/\
   CONVOLUTION_CASE(29) /* 59*/\
   CONVOLUTION_CASE(30) /* 61*/\
   CONVOLUTION_CASE(31) /* 63*/\
   }

float4 Convolution(read_only image2d_t source, CONST_ARG float * matrix, private int matrix_width)
{
   BEGIN

   private const int mask_size = matrix_width / 2;
   private float4 sum = {0, 0, 0, 0};
   int Index = 0;

   CONVOLUTION_SWITCH

   return sum;
}

void convolution(read_only image2d_t source, write_only image2d_t dest, CONST_ARG float * matrix,
   private int matrix_width)
{
   BEGIN

   float4 sum = Convolution(source, matrix, matrix_width);

   WRITE_IMAGE(dest, pos, sum);
}

float4 Combine(float4 color1, float4 color2)
{
   return sqrt(color1 * color1 + color2 * color2);
}

kernel void gaussian_blur(read_only image2d_t source, write_only image2d_t dest, constant const float * matrix, private int mask_size)
{
   // Does gaussian blur on first channel of image - receives a pre-calculated mask

   BEGIN

   private float4 sum = {0, 0, 0, 0};
   int Index = 0;

   CONVOLUTION_SWITCH

   WRITE_IMAGE(dest, pos, sum);
}

kernel void gaussian3(read_only image2d_t source, write_only image2d_t dest)
{
   CONST float matrix[9] = {
      1.f/16, 2.f/16, 1.f/16,
      2.f/16, 4.f/16, 2.f/16,
      1.f/16, 2.f/16, 1.f/16};

   convolution(source, dest, matrix, 3);
}

kernel void gaussian5(read_only image2d_t source, write_only image2d_t dest)
{
   CONST float matrix[25] = {
       2.f/571,  7.f/571,  12.f/571,  7.f/571,  2.f/571,
       7.f/571, 31.f/571,  52.f/571, 31.f/571,  7.f/571,
      12.f/571, 52.f/571, 127.f/571, 52.f/571, 12.f/571,
       7.f/571, 31.f/571,  52.f/571, 31.f/571,  7.f/571,
       2.f/571,  7.f/571,  12.f/571,  7.f/571,  2.f/571};

   convolution(source, dest, matrix, 5);
}

kernel void sobelH3(read_only image2d_t source, write_only image2d_t dest)
{
   CONST float matrix[9] = {
      -1, -2, -1,
       0,  0,  0,
       1,  2,  1};

   convolution(source, dest, matrix, 3);
}

kernel void sobelV3(read_only image2d_t source, write_only image2d_t dest)
{
   CONST float matrix[9] = {
      1, 0, -1,
      2, 0, -2,
      1, 0, -1};

   convolution(source, dest, matrix, 3);
}

kernel void sobelH5(read_only image2d_t source, write_only image2d_t dest)
{
   CONST float matrix[25] = {
      -1, -4,  -6, -4, -1,
      -2, -8, -12, -8, -2,
       0,  0,   0,  0,  0,
       2,  8,  12,  8,  2,
       1,  4,   6,  4,  1};

   convolution(source, dest, matrix, 5);
}

kernel void sobelV5(read_only image2d_t source, write_only image2d_t dest)
{
   CONST float matrix[25] = {
      1,  2, 0,  -2, -1,
      4,  8, 0,  -8, -4,
      6, 12, 0, -12, -6,
      4,  8, 0,  -8, -4,
      1,  2, 0,  -2, -1};

   convolution(source, dest, matrix, 5);
}

kernel void sobelCross3(read_only image2d_t source, write_only image2d_t dest)
{
   CONST float matrix[9] = {
      -1, 0,  1,
       0, 0,  0,
       1, 0, -1};

   convolution(source, dest, matrix, 3);
}

kernel void sobelCross5(read_only image2d_t source, write_only image2d_t dest)
{
   CONST float matrix[25] = {
      -1, -2, 0,  2,  1,
      -2, -4, 0,  4,  2,
       0,  0, 0,  0,  0,
       2,  4, 0, -4, -2,
       1,  2, 0, -2, -1};

   convolution(source, dest, matrix, 5);
}

kernel void sobel3(read_only image2d_t source, write_only image2d_t dest)
{
   BEGIN

   CONST float matrixH[9] = {
      -1, -2, -1,
       0,  0,  0,
       1,  2,  1};

   CONST float matrixV[9] = {
      1, 0, -1,
      2, 0, -2,
      1, 0, -1};

   float4 sumH = Convolution(source, matrixH, 3);
   float4 sumV = Convolution(source, matrixV, 3);

   float4 Result = Combine(sumH, sumV);

   WRITE_IMAGE(dest, pos, Result);
}

kernel void sobel5(read_only image2d_t source, write_only image2d_t dest)
{
   BEGIN

   CONST float matrixH[25] = {
      -1, -4,  -6, -4, -1,
      -2, -8, -12, -8, -2,
       0,  0,   0,  0,  0,
       2,  8,  12,  8,  2,
       1,  4,   6,  4,  1};

   CONST float matrixV[25] = {
      1,  2, 0,  -2, -1,
      4,  8, 0,  -8, -4,
      6, 12, 0, -12, -6,
      4,  8, 0,  -8, -4,
      1,  2, 0,  -2, -1};

   float4 sumH = Convolution(source, matrixH, 5);
   float4 sumV = Convolution(source, matrixV, 5);

   WRITE_IMAGE(dest, pos, Combine(sumH, sumV));
}

kernel void prewittH3(read_only image2d_t source, write_only image2d_t dest)
{
   CONST float matrix[9] = {
      -1, -1, -1,
       0,  0,  0,
       1,  1,  1};

   convolution(source, dest, matrix, 3);
}

kernel void prewittV3(read_only image2d_t source, write_only image2d_t dest)
{
   CONST float matrix[9] = {
      1, 0, -1,
      1, 0, -1,
      1, 0, -1};

   convolution(source, dest, matrix, 3);
}

kernel void prewitt3(read_only image2d_t source, write_only image2d_t dest)
{
   BEGIN

   CONST float matrixH[9] = {
      -1, -1, -1,
       0,  0,  0,
       1,  1,  1};

   CONST float matrixV[9] = {
      1, 0, -1,
      1, 0, -1,
      1, 0, -1};

   float4 sumH = Convolution(source, matrixH, 3);
   float4 sumV = Convolution(source, matrixV, 3);

   WRITE_IMAGE(dest, pos, Combine(sumH, sumV));
}

kernel void scharrH3(read_only image2d_t source, write_only image2d_t dest)
{
   CONST float matrix[9] = {
      -3, -10, -3,
       0,   0,  0,
       3,  10,  3};

   convolution(source, dest, matrix, 3);
}

kernel void scharrV3(read_only image2d_t source, write_only image2d_t dest)
{
   CONST float matrix[9] = {
       -3, 0,  3,
      -10, 0, 10,
       -3, 0,  3};

   convolution(source, dest, matrix, 3);
}

kernel void scharr3(read_only image2d_t source, write_only image2d_t dest)
{
   BEGIN

   CONST float matrixH[9] = {
      -3, -10, -3,
       0,   0,  0,
       3,  10,  3};

   CONST float matrixV[9] = {
       -3, 0,  3,
      -10, 0, 10,
       -3, 0,  3};

   float4 sumH = Convolution(source, matrixH, 3);
   float4 sumV = Convolution(source, matrixV, 3);

   WRITE_IMAGE(dest, pos, Combine(sumH, sumV));
}

kernel void hipass3(read_only image2d_t source, write_only image2d_t dest)
{
   CONST float matrix[9] = {
      -1, -1, -1,
      -1,  8, -1,
      -1, -1, -1};

   convolution(source, dest, matrix, 3);
}

kernel void hipass5(read_only image2d_t source, write_only image2d_t dest)
{
   CONST float matrix[25] = {
      -1, -1, -1, -1, -1,
      -1, -1, -1, -1, -1,
      -1, -1, 24, -1, -1,
      -1, -1, -1, -1, -1,
      -1, -1, -1, -1, -1};

   convolution(source, dest, matrix, 5);
}

kernel void laplace3(read_only image2d_t source, write_only image2d_t dest)
{
   CONST float matrix[9] = {
      -1, -1, -1,
      -1,  8, -1,
      -1, -1, -1};

   convolution(source, dest, matrix, 3);
}

kernel void laplace5(read_only image2d_t source, write_only image2d_t dest)
{
   CONST float matrix[25] = {
      -1, -3, -4, -3, -1,
      -3,  0,  6,  0, -3,
      -4,  6, 20,  6, -4,
      -3,  0,  6,  0, -3,
      -1, -3, -4, -3, -1};

   convolution(source, dest, matrix, 5);
}

kernel void sharpen3(read_only image2d_t source, write_only image2d_t dest)
{
   CONST float matrix[9] = {
      -1.f/8, -1.f/8, -1.f/8,
      -1.f/8, 16.f/8, -1.f/8,
      -1.f/8, -1.f/8, -1.f/8};

   convolution(source, dest, matrix, 3);
}

// Smooth convolution (box filter - a convolution matrix filled with 1/Nb)
#undef CONVOLUTION_CASE
#define CONVOLUTION_CASE(size)\
   case size:\
   {\
      for (int y = -size; y <= size; y++)\
         for (int x = -size; x <= size; x++)\
            sum += factor * READ_IMAGE(source, pos + (int2)(x, y));\
   }\
   break;

kernel void smooth(read_only image2d_t source, write_only image2d_t dest, int matrix_width)    // Box filter
{
   BEGIN

   const int mask_size = matrix_width / 2;
   float4 sum = {0, 0, 0, 0};
   float factor = 1.f / (matrix_width * matrix_width);

   CONVOLUTION_SWITCH

   WRITE_IMAGE(dest, pos, sum);
}

// Median

//The following macro puts the smallest value in position a and biggest in position b
#define s2(a, b)                Tmp = values[a]; values[a] = min(values[a], values[b]); values[b] = max(Tmp, values[b]);

//The following min macro make sur the first element is the minimum of a set (the remaining elements are in random order)
//The following max macro make sure the last element is the maximum of a set (the remaining elements are in random order)
#define min3(a, b, c)           s2(a, b); s2(a, c);
#define max3(a, b, c)           s2(b, c); s2(a, c);
#define min4(a,b,c,d)           min3(b, c, d); s2(a, b); 
#define max4(a,b,c,d)           max3(a, b, c); s2(c, d);
#define min5(a,b,c,d,e)         min4(b, c, d, e); s2(a, b); 
#define max5(a,b,c,d,e)         max4(a, b, c, d); s2(d, e);
#define min6(a,b,c,d,e,f)       min5(b, c, d, e, f); s2(a, b);
#define max6(a,b,c,d,e,f)       max5(a, b, c, d, e); s2(e, f);
#define min7(a,b,c,d,e,f,g)     min6(b, c, d, e, f, g); s2(a, b);
#define max7(a,b,c,d,e,f,g)     max6(a, b, c, d, e, f); s2(f, g);

//The following mnmx macro make sure the first element is the minimum and the last element is the maximum (the remaining elements are in random order)
#define mnmx3(a, b, c)          max3(a, b, c); s2(a, b);                                    // 3 exchanges
#define mnmx4(a, b, c, d)       s2(a, b); s2(c, d); s2(a, c); s2(b, d);                     // 4 exchanges
#define mnmx5(a, b, c, d, e)    s2(a, b); s2(c, d); min3(a, c, e); max3(b, d, e);           // 6 exchanges
#define mnmx6(a, b, c, d, e, f) s2(a, d); s2(b, e); s2(c, f); min3(a, b, c); max3(d, e, f); // 7 exchanges
#define mnmx7(a,b,c,d,e,f,g)    s2(d,g); s2(a,e); s2(b,f); s2(c,g); min4(a,b,c,d); max3(e,f,g);
#define mnmx8(a,b,c,d,e,f,g,h)  s2(a,e); s2(b,f); s2(c,g); s2(d,h); min4(a,b,c,d); max4(e,f,g,h);
#define mnmx9(a,b,c,d,e,f,g,h,i) s2(e,i); s2(a,f); s2(b,g); s2(c,h); s2(d,i); min5(a,b,c,d,e); max4(f,g,h,i);
#define mnmx10(a,b,c,d,e,f,g,h,i,j) s2(a,f); s2(b,g); s2(c,h); s2(d,i); s2(e,j); min5(a,b,c,d,e); max5(f,g,h,i,j);
#define mnmx11(a,b,c,d,e,f,g,h,i,j,k) s2(f,k); s2(a,g); s2(b,h); s2(c,i); s2(d,j); s2(e,k); min6(a,b,c,d,e,f); max5(g,h,i,j,k);
#define mnmx12(a,b,c,d,e,f,g,h,i,j,k,l) s2(a,g); s2(b,h); s2(c,i); s2(d,j); s2(e,k); s2(f,l); min6(a,b,c,d,e,f); max6(g,h,i,j,k,l);
#define mnmx13(a,b,c,d,e,f,g,h,i,j,k,l,m)  s2(g,m); s2(a,h); s2(b,i); s2(c,j); s2(d,k); s2(e,l); s2(f,m); min7(a,b,c,d,e,f,g); max6(h,i,j,k,l,m);
#define mnmx14(a,b,c,d,e,f,g,h,i,j,k,l,m,n) s2(a,h); s2(b,i); s2(c,j); s2(d,k); s2(e,l); s2(f,m); s2(g,n); min7(a,b,c,d,e,f,g); max7(h,i,j,k,l,m,n);

float calculate_median3(float * values)
{
   float Tmp;

   // Starting with a subset of size 6, remove the min and max each time
   mnmx6(0,1,2,3,4,5);
   mnmx5(1,2,3,4,6);
   mnmx4(2,3,4,7);
   mnmx3(3,4,8);
   
   return values[4];
}

float calculate_median5(float * values)
{
   float Tmp;

   mnmx14(0,1,2,3,4,5,6,7,8,9,10,11,12,13);
   mnmx13(1,2,3,4,5,6,7,8,9,10,11,12,14);
   mnmx12(2,3,4,5,6,7,8,9,10,11,12,15);
   mnmx11(3,4,5,6,7,8,9,10,11,12,16);
   mnmx10(4,5,6,7,8,9,10,11,12,17);
   mnmx9( 5,6,7,8,9,10,11,12,18);
   mnmx8( 6,7,8,9,10,11,12,19);
   mnmx7( 7,8,9,10,11,12,20);
   mnmx6( 8,9,10,11,12,21);
   mnmx5( 9,10,11,12,22);
   mnmx4( 10,11,12,23);
   mnmx3( 11,12,24);

   return values[12];
}

#define LW 16  // local width
#define MW 3   // Matrix width
__attribute__((reqd_work_group_size(LW, LW, 1)))
kernel void median3_cached(read_only image2d_t source, write_only image2d_t dest)
{
   BEGIN

   const int lid = get_local_id(1) * get_local_size(0) + get_local_id(0);

   // Cache pixels
   local float cache[LW * LW];
   cache[lid] = READ_IMAGE(source, pos).x;
   barrier(CLK_LOCAL_MEM_FENCE);

   // Cache information
   int bitmask = LW - 1;
   int x_cache_begin = gx - (gx & bitmask);
   int x_cache_end = x_cache_begin + LW;
   int y_cache_begin = gy - (gy & bitmask);
   int y_cache_end = y_cache_begin + LW;

   const int matrix_width = MW;
   const int mask_size = matrix_width / 2;

   // Read values in a local array
   float values[MW * MW];

   int Index = 0;
   for (int y = -mask_size; y <= mask_size; y++)
   {
      int py = gy + y;
      if (py < y_cache_begin || py >= y_cache_end)
      {
         for (int x = -mask_size; x <= mask_size; x++)
            values[Index++] = READ_IMAGE(source, pos + (int2)(x, y)).x;
      }
      else
      {
         for (int x = -mask_size; x <= mask_size; x++)
         {
            int px = gx + x;
            if (px < x_cache_begin || px >= x_cache_end)
               values[Index++] = READ_IMAGE(source, (int2)(px, py)).x;
            else
            {
               // Read from cache
               int cache_y = py - y_cache_begin;
               int cache_x = px - x_cache_begin;
               values[Index++] = cache[cache_y * LW + cache_x];
            }

         }

      }

   }

   // Calculate median
   float Result = calculate_median3(values);
   
   // Save result
   TYPE px = {Result, 0, 0, 1};
   WRITE_IMAGE(dest, pos, px);
}

kernel void median3(read_only image2d_t source, write_only image2d_t dest)
{
   BEGIN

   const int matrix_width = MW;
   const int mask_size = matrix_width / 2;

   // Read values in a local array
   float values[MW * MW];

   int Index = 0;
   for (int y = -mask_size; y <= mask_size; y++)
      for (int x = -mask_size; x <= mask_size; x++)
         values[Index++] = READ_IMAGE(source, pos + (int2)(x, y)).x;

   // Calculate median
   float Result = calculate_median3(values);
   
   // Save result
   TYPE px = {Result, 0, 0, 1};
   WRITE_IMAGE(dest, pos, px);
}


#undef MW
#define MW 5   // Matrix width

kernel void median5(read_only image2d_t source, write_only image2d_t dest)
{
   BEGIN

   const int matrix_width = MW;
   const int mask_size = matrix_width / 2;

   // Read values in a local array
   float values[MW * MW];

   int Index = 0;
   for (int y = -mask_size; y <= mask_size; y++)
      for (int x = -mask_size; x <= mask_size; x++)
         values[Index++] = READ_IMAGE(source, pos + (int2)(x, y)).x;

   // Calculate median
   float Result = calculate_median5(values);
   
   // Save result
   TYPE px = {Result, 0, 0, 1};
   WRITE_IMAGE(dest, pos, px);
}
