# CustomKeyboardMVP v2

Inclui:
- teclado básico;
- emotes;
- stickers de texto;
- troca de cor;
- histórico local opcional;
- backup automático configurável (12h, 24h, 7 dias);
- destino de backup configurável;
- status de último backup;
- botão de limpar histórico.

## Como funciona o backup
O iOS não garante execução exata em segundo plano para uma Keyboard Extension.
Então o app verifica o prazo sempre que o teclado é usado. Se o intervalo configurado venceu,
o backup é disparado na próxima oportunidade de uso.

## Transporte
Este template usa um endpoint HTTP configurável para receber o backup.
O destino padrão está vazio. Configure no app principal antes de testar.

Payload JSON:
{
  "email": "destino@exemplo.com",
  "createdAt": "ISO-8601",
  "entries": ["..."]
}

O endpoint deve aceitar POST application/json e enviar/armazenar o conteúdo como você preferir.

## Assinatura
Troque os bundle IDs antes de assinar:
- com.example.CustomKeyboardMVP
- com.example.CustomKeyboardMVP.KeyboardExtension
