# O google_mlkit_text_recognition referencia os reconhecedores de outros
# alfabetos (chinês, japonês, coreano e devanágari), mas o app só inclui o
# latino. Sem estas regras o R8 falha no build de release.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
