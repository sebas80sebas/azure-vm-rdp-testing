   @echo off
   :loop
   echo %date% %time% - Programa ejecutandose >> C:\test\log.txt
   timeout /t 60
   goto loop
