////////////////////////////////////////////////////////////////////////////////
//! @file	: benchGradient.hpp
//! @date   : Jul 2013
//!
//! @brief  : Benchmark class for Gradient morphology operation (3x3)
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

class GradientBench : public MorphoBenchBase
{
public:
   void RunIPP();
   void RunCUDA();
   void RunCL();
   void RunNPP();
};
//-----------------------------------------------------------------------------------------------------------------------------
void GradientBench::RunIPP()
{
   IPP_CODE(
      ippiErode3x3_8u_C1R(m_ImgSrc.Data(1, 1), m_ImgSrc.Step, m_ImgTemp.Data(1, 1), m_ImgTemp.Step, m_ROI1);
      ippiDilate3x3_8u_C1R(m_ImgSrc.Data(1, 1), m_ImgSrc.Step, m_ImgDstIPP.Data(1, 1), m_ImgDstIPP.Step, m_ROI1);

      // Dilate(Dst) - Erode(Temp)
      ippiSub_8u_C1RSfs(m_ImgTemp.Data(), m_ImgTemp.Step, m_ImgDstIPP.Data(), m_ImgDstIPP.Step, 
         m_ImgDstIPP.Data(), m_ImgDstIPP.Step, m_IPPRoi, 0);
      )
}
//-----------------------------------------------------------------------------------------------------------------------------
void GradientBench::RunCL()
{
   if (m_UsesBuffer)
      ocipGradient_B(m_CLBufferSrc, m_CLBufferDst, m_CLBufferTmp, 3);
   else
      ocipGradient(m_CLSrc, m_CLDst, m_CLTmp, 3);
}
//-----------------------------------------------------------------------------------------------------------------------------
void GradientBench::RunCUDA()
{
   CUDA_CODE(
      CUDAPP(Gradient_8u_C1)((unsigned char*) m_CUDASrc,
         m_CUDASrcStep,
         (unsigned char*) m_CUDATmp,
         m_CUDATmpStep,
         (unsigned char*) m_CUDADst,
         m_CUDADstStep,
         m_ImgSrc.Width,
         m_ImgSrc.Height,
         m_MaskSize.Width,
         m_MaskSize.Height,
         m_MaskAnchor.X,
         m_MaskAnchor.Y);
      )
}
//-----------------------------------------------------------------------------------------------------------------------------
void GradientBench::RunNPP()
{
   NPP_CODE(
      // Gradient
      nppiErode3x3_8u_C1R((Npp8u*) m_NPPSrc, m_NPPSrcStep, (Npp8u*) m_NPPDst, m_NPPDstStep, m_NPPRoi);
      nppiDilate3x3_8u_C1R((Npp8u*) m_NPPSrc, m_NPPSrcStep, m_NPPTmp, m_NPPTmpStep, m_NPPRoi);
   
      // Dilate(Tmp) - Erode(Dst)
      nppiSub_8u_C1RSfs((Npp8u*) m_NPPDst, m_NPPDstStep, m_NPPTmp, m_NPPTmpStep, (Npp8u*) m_NPPDst, m_NPPDstStep, m_NPPRoi, 0);
      )
}
