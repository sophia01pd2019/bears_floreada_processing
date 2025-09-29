parentdir <- '/Users/chsiung/GDrive/Chris-Ray-share/Flow/2021-10-24_chsiung_Exp1-K562-pCH38-MOI-Day6'


source( '/Users/chsiung/Dropbox/Postdoc/Flow/MetaAnalysis/FlowAnalysis/flowenv.R' )

setwd(parentdir)

singlets <- processFlowjoExportDir( dir = file.path(parentdir, 'flowjoexport'), csvstring = '_P3.csv', fileout = 'P3_combodf.txt' )

GFPpos <- processFlowjoExportDir( dir = file.path(parentdir, 'flowjoexport'), csvstring = '_GFPpos.csv', fileout = 'GFPpos_combodf.txt' )

# mChpos <- processFlowjoExportDir( dir = file.path(parentdir, 'flowjoexport'), csvstring = '_mChpos.csv', fileout = 'mChpos_combodf.txt' )
