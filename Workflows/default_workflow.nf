nextflow.enable.dsl=2

// The values are assigned inside the batch script
// Based on internal values and options provided in the request
params.input_file_group = "null"
params.mets = "null"
params.workspace_dir = "null"
params.singularity_wrapper = "null"
params.cpus = "null"
params.ram = "null"

log.info """\
         O P E R A N D I - H P C - default_workflow
         ===========================================
         input_file_group    : ${params.input_file_group}
         mets                : ${params.mets}
         workspace_dir       : ${params.workspace_dir}
         singularity_wrapper : ${params.singularity_wrapper}
         cpus                : ${params.cpus}
         ram                 : ${params.ram}
         """
         .stripIndent()

process ocrd_cis_ocropy_binarize {
  maxForks 1
  cpus params.cpus
  memory params.ram
  debug true

  input:
    path mets_file
    val input_group
    val output_group

  output:
    path mets_file

  script:
  """
  ${params.singularity_wrapper} ocrd-cis-ocropy-binarize -w !{params.workspace_dir} -m ${mets_file} -I ${input_group} -O ${output_group}
  """
}

process ocrd_anybaseocr_crop {
  maxForks 1
  cpus params.cpus
  memory params.ram
  debug true

  input:
    path mets_file
    val input_group
    val output_group

  output:
    path mets_file

  script:
  """
  ${params.singularity_wrapper} ocrd-anybaseocr-crop -w !{params.workspace_dir} -m ${mets_file} -I ${input_group} -O ${output_group}
  """
}

process ocrd_skimage_binarize {
  maxForks 1
  cpus params.cpus
  memory params.ram
  debug true

  input:
    path mets_file
    val input_group
    val output_group

  output:
    path mets_file

  script:
  """
  ${params.singularity_wrapper} ocrd-skimage-binarize -w !{params.workspace_dir} -m ${mets_file} -I ${input_group} -O ${output_group} -p '{"method": "li"}'
  """
}

process ocrd_skimage_denoise {
  maxForks 1
  cpus params.cpus
  memory params.ram
  debug true

  input:
    path mets_file
    val input_group
    val output_group

  output:
    path mets_file

  script:
  """
  ${params.singularity_wrapper} ocrd-skimage-denoise -w !{params.workspace_dir} -m ${mets_file} -I ${input_group} -O ${output_group} -p '{"level-of-operation": "page"}'
  """
}

process ocrd_tesserocr_deskew {
  maxForks 1
  cpus params.cpus
  memory params.ram
  debug true

  input:
    path mets_file
    val input_group
    val output_group

  output:
    path mets_file

  script:
  """
  ${params.singularity_wrapper} ocrd-tesserocr-deskew -w !{params.workspace_dir} -m ${mets_file} -I ${input_group} -O ${output_group} -p '{"operation_level": "page"}'
  """
}

process ocrd_cis_ocropy_segment {
  maxForks 1
  cpus params.cpus
  memory params.ram
  debug true

  input:
    path mets_file
    val input_group
    val output_group

  output:
    path mets_file

  script:
  """
  ${params.singularity_wrapper} ocrd-cis-ocropy-segment -w !{params.workspace_dir} -m ${mets_file} -I ${input_group} -O ${output_group} -p '{"level-of-operation": "page"}'
  """
}

process ocrd_cis_ocropy_dewarp {
  maxForks 1
  cpus params.cpus
  memory params.ram
  debug true

  input:
    path mets_file
    val input_group
    val output_group

  output:
    path mets_file

  script:
  """
  ${params.singularity_wrapper} ocrd-cis-ocropy-dewarp -w !{params.workspace_dir} -m ${mets_file} -I ${input_group} -O ${output_group}
  """
}

process ocrd_calamari_recognize {
  maxForks 1
  cpus params.cpus
  memory params.ram
  debug true

  input:
    path mets_file
    val input_group
    val output_group

  output:
    path mets_file

  script:
  """
  ${params.singularity_wrapper} ocrd-calamari-recognize -w !{params.workspace_dir} -m ${mets_file} -I ${input_group} -O ${output_group} -p '{"checkpoint_dir": "qurator-gt4histocr-1.0"}'
  """
}


workflow {
  main:
    ocrd_cis_ocropy_binarize(params.mets, params.input_file_group, "OCR-D-BIN")
    ocrd_anybaseocr_crop(ocrd_cis_ocropy_binarize.out, "OCR-D-BIN", "OCR-D-CROP")
    ocrd_skimage_binarize(ocrd_anybaseocr_crop.out, "OCR-D-CROP", "OCR-D-BIN2")
    ocrd_skimage_denoise(ocrd_skimage_binarize.out, "OCR-D-BIN2", "OCR-D-BIN-DENOISE")
    ocrd_tesserocr_deskew(ocrd_skimage_denoise.out, "OCR-D-BIN-DENOISE", "OCR-D-BIN-DENOISE-DESKEW")
    ocrd_cis_ocropy_segment(ocrd_tesserocr_deskew.out, "OCR-D-BIN-DENOISE-DESKEW", "OCR-D-SEG")
    ocrd_cis_ocropy_dewarp(ocrd_cis_ocropy_segment.out, "OCR-D-SEG", "OCR-D-SEG-LINE-RESEG-DEWARP")
    ocrd_calamari_recognize(ocrd_cis_ocropy_dewarp.out, "OCR-D-SEG-LINE-RESEG-DEWARP", "OCR-D-OCR")
}

