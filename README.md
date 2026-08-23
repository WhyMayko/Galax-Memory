# Galax Memory

Biblioteca de memória para Matcha. Ela obtém `Offsets.json` e `types.json`, exige que ambos sejam da mesma versão e converte a leitura/escrita para o tipo correto. Não há offsets fixos nos scripts consumidores.

## Carregamento

Execute `GalaxMemory.lua` antes do script consumidor. O arquivo registra `GalaxMemory` no ambiente global do Matcha, porque o `return` de um chunk carregado por `loadstring` é descartado pelo runtime.

```lua
loadstring(game:HttpGet("URL/DO/GalaxMemory.lua"))()
local memory = GalaxMemory.new()
```

`GalaxMemory.new()` tenta três fontes para cada documento. Se você hospedar os arquivos em outro lugar, informe os pares de URLs equivalentes:

```lua
local memory = GalaxMemory.new({
    offseturls = { "https://host/Offsets.json" },
    typeurls = { "https://host/types.json" },
})
```

## Uso

```lua
local humanoid = memory:bind(game:GetService("Players").LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid"))
humanoid.WalkSpeed = 50
humanoid.Sit = true
print(humanoid.Health)

local camera = memory:bind(workspace.CurrentCamera)
camera.FieldOfView = 100
print(camera.Position)
```

`bind` escolhe a classe mais específica disponível no dump e também aceita uma classe-base explícita: `memory:bind(part, "BasePart")`. Nomes de propriedades ignoram maiúsculas, minúsculas e separadores, portanto `WalkSpeed` resolve para o offset `Walkspeed` atual.

Para a UI interna do Roblox, use sempre o proxy de memória, não a instância original:

```lua
local screen = memory:bind(screenGui)
screen.Enabled = false

local label = memory:bind(textLabel)
label.Visible = false
```

`ScreenGui.Enabled` usa exclusivamente o offset `ScreenGui_Enabled`. Em um `ScreenGui`, a biblioteca não expõe `Visible`, pois essa propriedade não pertence a essa classe; isso evita ler ou escrever um offset de `GuiObject` no tipo errado.

`BasePart.Color3` é lido como três bytes RGB consecutivos e retorna um `Color3` normalizado. A estrutura foi validada no `Head` do personagem com os bytes `F8 F8 F8`, equivalentes a `RGB(248, 248, 248)`. Essa propriedade é somente leitura enquanto a escrita não for validada separadamente.

Para uma classificação visual simples baseada somente no `Head`, vincule o `Model` do personagem e leia `DarkColor` como uma propriedade. Ela calcula a luminância de `Color3` e retorna `true` para valores de até 50%.

```lua
local character = memory:bind(rawcharacter)
print(character.DarkColor)
```

`DarkColor` é somente leitura. Para usar outro limiar entre `0` e `1`, use `memory:darkcolor(rawcharacter, threshold)`.

Outros valores calculados podem usar o mesmo padrão: `memory:virtual("Classe", "Propriedade", getter)`. Registre antes de chamar `bind`; depois, a propriedade aparece no proxy como um valor de leitura, por exemplo `proxy.Propriedade`.

Para uso sem proxy: `memory:read(instance, "Health")` e `memory:write(instance, "Health", 100)`.

## Tipos suportados

Leitura: `bool`, `byte`, `int`, `float`, `double`, ponteiros, `string`, `Vector2`, `Vector3`, `Color3`, `UDim2` e matrizes 3×3. Escrita é validada por tipo; `string`, matrizes e tipos `unknown` são somente leitura por segurança. `UDim2` usa a tabela `{ xscale, xoffset, yscale, yoffset }`.

Toda operação valida instância, endereço, classe, propriedade e tipo. Falhas interrompem a operação com uma mensagem explícita; a biblioteca nunca usa uma leitura alternativa silenciosa.

## Validação

Execute `Validate.lua` depois de carregar a biblioteca para uma verificação somente de leitura. Ele examina uma instância de cada classe que existe no jogo aberto e tenta ler todas as propriedades expostas pelo proxy, imprimindo `Classe:propriedades:falhas`. Classes que não estão presentes no jogo não podem ser validadas naquele cliente; o dump ainda as mantém disponíveis para jogos onde existam.
