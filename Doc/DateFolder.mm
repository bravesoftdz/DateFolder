<?xml version="1.0" encoding="UTF-8"?>
<map version="0.9.0">
<!-- This file is saved using a hacked version of FreeMind. visit: http://freemind-mmx.sourceforge.net -->
<!-- Orignal FreeMind, can download from http://freemind.sourceforge.net -->
<!-- This .mm file is CVS/SVN friendly, some atts are saved in .mmx file. (from ossxp.com) -->
<node ID="ID_1971707192" 
	TEXT="DateFolder">
<node FOLDED="true" ID="ID_837947179" POSITION="right" 
	TEXT="目的">
<node ID="ID_764760194">
<richcontent TYPE="NODE"><html>
  <head>
    
  </head>
  <body>
    <p>
      通过读取图片EXIF日期，生成相应目录，并将其放入其中。
    </p>
    <p>
      如果没有EXIF日期，则读取文件生成时间。
    </p>
  </body>
</html></richcontent>
</node>
</node>
<node FOLDED="true" ID="ID_135935193" POSITION="right" 
	TEXT="参数">
<node ID="ID_803467444" 
	TEXT="需要处理的相片目录，如 D:\Photo\"/>
<node ID="ID_983554322" 
	TEXT="相片要放置的目录名称，如 Nikon D80"/>
<node ID="ID_1290128808" 
	TEXT="另外需要创建的目录列表，如 Public;PS等"/>
<node ID="ID_615400169" 
	TEXT="日期格式，如 yyyy_mm_dd，表示日期格式为 1989_06_04 这样"/>
<node ID="ID_647396207" 
	TEXT="扩展名过滤，如 *.jpg;*.tiff"/>
<node ID="ID_451532224" 
	TEXT="处理模式选择：移动或者复制"/>
<node ID="ID_1631901437" 
	TEXT="输出的临时文件目录，如 D:\temp\"/>
</node>
<node FOLDED="true" ID="ID_1933513122" POSITION="right" 
	TEXT="流程">
<node ID="ID_1172525834" 
	TEXT="检查参数有效性，对置空参数设为缺省值"/>
<node ID="ID_790056259" 
	TEXT="扫描相片目录，获得文件列表"/>
<node ID="ID_273058089" 
	TEXT="根据扩展名过滤出需要处理的文件列表"/>
<node FOLDED="true" ID="ID_783637249" 
	TEXT="依次对每张照片文件进行处理">
<node ID="ID_1873078702" 
	TEXT="尝试获取相片的EXIF信息中的日期信息，如果失败，则用生成日期来代替，如 1989_06_04"/>
<node ID="ID_1463775845" 
	TEXT="如果该日期对应的临时目录不存在，则创建之，如 D:\temp\1989_06_04\Nikon D80"/>
<node ID="ID_332623677" 
	TEXT="将文件复制到此目录"/>
<node ID="ID_560552475" 
	TEXT="如果复制成功，且选择了移动，则删除原始文件"/>
<node ID="ID_542614982" 
	TEXT="创建其他需要创建的目录列表，如 Public 和 PS 等"/>
</node>
</node>
<node FOLDED="true" ID="ID_673458840" POSITION="right" 
	TEXT="技术">
<node FOLDED="true" ID="ID_1818935213" 
	TEXT="获取照片EXIF信息">
<node ID="ID_726493138" LINK="http://delphihaven.wordpress.com/ccr-exif/" 
	TEXT="CCR Exif"/>
<node ID="ID_1471848429" 
	TEXT="dEXIF"/>
</node>
<node ID="ID_227999078" 
	TEXT="获取文件时间"/>
</node>
<node FOLDED="true" ID="ID_969264961" POSITION="right" 
	TEXT="举例">
<node ID="ID_103821496">
<richcontent TYPE="NODE"><html>
  <head>
    
  </head>
  <body>
    <p>
      └─2017_07_08
    </p>
    <p>
          ├─Instagram
    </p>
    <p>
          ├─iPhone 6s
    </p>
    <p>
          │      IMG_0137.PNG
    </p>
    <p>
          │      IMG_0138.JPG
    </p>
    <p>
          │      IMG_0139.JPG
    </p>
    <p>
          │
    </p>
    <p>
          └─Video
    </p>
    <p>
                  IMG_0140.MOV
    </p>
  </body>
</html>
</richcontent>
</node>
</node>
</node>
</map>
