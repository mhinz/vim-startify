scriptencoding utf-8

" Function: s:get_random_offset {{{1
function! s:get_random_offset(max) abort
  return str2nr(matchstr(reltimestr(reltime()), '\.\zs\d\+')[1:]) % a:max
endfunction

" Function: s:draw_box {{{1
function! s:draw_box(lines) abort
  let longest_line = max(map(copy(a:lines), 'strwidth(v:val)'))
  let top_bottom_without_corners = repeat(s:char_top_bottom, longest_line + 2)
  let top = s:char_top_left . top_bottom_without_corners . s:char_top_right
  let bottom = s:char_bottom_left . top_bottom_without_corners . s:char_bottom_right
  let lines = [top]
  for l in a:lines
    let offset = longest_line - strwidth(l)
    let lines += [s:char_sides . ' '. l . repeat(' ', offset) .' ' . s:char_sides]
  endfor
  let lines += [bottom]
  return lines
endfunction

" Function: #quote {{{1
function! startify#fortune#quote() abort
  return g:startify_custom_header_quotes[s:get_random_offset(len(g:startify_custom_header_quotes))]
endfunction

" Function: #boxed {{{1
function! startify#fortune#boxed(...) abort
  let wrapped_quote = []
  if a:0 && type(a:1) == type([])
    let quote = a:1
  else
    let Quote = startify#fortune#quote()
    let quote = type(Quote) == type(function('tr')) ? Quote() : Quote
  endif
  for line in quote
    let wrapped_quote += split(line, '\%50c.\{-}\zs\s', 1)
  endfor
  let wrapped_quote = s:draw_box(wrapped_quote)
  return wrapped_quote
endfunction

" Function: #cowsay {{{1
function! startify#fortune#cowsay(...) abort
  if a:0
    let quote = a:0 && type(a:1) == type([]) ? a:1 : startify#fortune#quote()
    let s:char_top_bottom   = get(a:000, 1, s:char_top_bottom)
    let s:char_sides        = get(a:000, 2, s:char_sides)
    let s:char_top_left     = get(a:000, 3, s:char_top_left)
    let s:char_top_right    = get(a:000, 4, s:char_top_right)
    let s:char_bottom_right = get(a:000, 5, s:char_bottom_right)
    let s:char_bottom_left  = get(a:000, 6, s:char_bottom_left)
  else
    let quote = startify#fortune#quote()
  endif
  let boxed_quote = startify#fortune#boxed(quote)
  return boxed_quote + s:cow
endfunction

" Function: #predefined_quotes {{{1
function! startify#fortune#predefined_quotes() abort
  return s:predefined_quotes
endfunction

" Variables {{{1
let s:cow = [
      \ '       o',
      \ '        o   ^__^',
      \ '         o  (oo)\_______',
      \ '            (__)\       )\/\',
      \ '                ||----w |',
      \ '                ||     ||',
      \ ]

let g:startify_fortune_use_unicode = &encoding == 'utf-8' && get(g:, 'startify_fortune_use_unicode')

let s:char_top_bottom   = ['-', '─'][g:startify_fortune_use_unicode]
let s:char_sides        = ['|', '│'][g:startify_fortune_use_unicode]
let s:char_top_left     = ['*', '╭'][g:startify_fortune_use_unicode]
let s:char_top_right    = ['*', '╮'][g:startify_fortune_use_unicode]
let s:char_bottom_right = ['*', '╯'][g:startify_fortune_use_unicode]
let s:char_bottom_left  = ['*', '╰'][g:startify_fortune_use_unicode]

let s:predefined_quotes = [
      \ ["A depuração é duas vezes mais difícil do que escrever o código em primeiro lugar. Portanto, se você escrever o código da maneira mais inteligente possível, por definição, não será inteligente o suficiente para depurá-lo.", '', '- Brian Kernighan'],
      \ ["Se você não terminar, estará apenas ocupado, não produtivo."],
      \ ['Adaptar programas antigos para caber em novas máquinas geralmente significa adaptar novas máquinas para se comportarem como as antigas.', '', '- Alan Perlis'],
      \ ['Os tolos ignoram a complexidade. Os pragmáticos sofrem com isso. Alguns podem evitá-lo. Os gênios o removem.', '', '- Alan Perlis'],
      \ ['É mais fácil alterar a especificação para se adequar ao programa do que vice-versa.', '', '- Alan Perlis'],
      \ ['A simplicidade não precede a complexidade, mas segue-a.', '', '- Alan Perlis'],
      \ ['A otimização impede a evolução.', '', '- Alan Perlis'],
      \ ['A recursão é a raiz da computação, pois troca descrição por tempo.', '', '- Alan Perlis'],
      \ ['É melhor ter 100 funções operando em uma estrutura de dados do que 10 funções em 10 estruturas de dados.', '', '- Alan Perlis'],
      \ ['Não há nada tão inútil quanto fazer com grande eficiência algo que não deveria ser feito.', '', '- Peter Drucker'],
      \ ["Se você não falhar pelo menos 90% das vezes, não está mirando alto o suficiente.", '', '- Alan Kay'],
      \ ['Acho que muitos novos programadores gostam de usar estruturas de dados avançadas e recursos avançados de linguagem como forma de demonstrar sua habilidade. Eu chamo isso de síndrome do domador de leões. Essas demonstrações são impressionantes, mas, a menos que realmente se traduzam em ganhos reais para o projeto, evite-as.', '', '- Glyn Williams'],
      \ ['Prefiro morrer de paixão do que de tédio.', '', '- Vincent Van Gogh'],
      \ ['Se um sistema deve servir ao espírito criativo, deve ser inteiramente compreensível para um único indivíduo.'],
      \ ["O principal desafio do cientista da computação é não se confundir com as complexidades de sua própria criação.", '', '- Edsger W. Dijkstra'],
      \ ["O progresso em um contexto fixo é quase sempre uma forma de otimização. Atos criativos geralmente não ficam no contexto em que estão.", '', '- Alan Kay'],
      \ ['A essência do XML é esta: o problema que ele resolve não é difícil e não resolve bem o problema.', '', '- Phil Wadler'],
      \ ['Um bom programador é alguém que sempre olha para os dois lados antes de atravessar uma rua de mão única.', '', '- Doug Linder'],
      \ ['Padrões significam "estou sem linguagem."', '', '- Rich Hickey'],
      \ ['Sempre codifique como se a pessoa que acaba mantendo seu código fosse um psicopata violento que sabe onde você mora.', '', '- John Woods'],
      \ ['O Unix não foi projetado para impedir que seus usuários façam coisas estúpidas, pois isso também os impediria de fazer coisas inteligentes.'],
      \ ['Ao contrário da crença popular, o Unix é amigável. Acontece que ele é muito seletivo sobre com quem decide fazer amizade.'],
      \ ['A perfeição é alcançada, não quando não há mais nada a acrescentar, mas quando não há mais nada para tirar.'],
      \ ['Existem duas maneiras de construir um projeto de software: uma maneira é torná-lo tão simples que obviamente não haja deficiências, e a outra maneira é torná-lo tão complicado que não haja deficiências óbvias.', '', '- C.A.R. Hoare'],
      \ ["Se você não comete erros, não está trabalhando em problemas difíceis o suficiente.", '', '- Frank Wilczek'],
      \ ["Se você não começar com uma especificação, cada trecho de código que você escrever será um patch.", '', '- Leslie Lamport'],
      \ ['Caches são bugs esperando para acontecer.', '', '- Rob Pike'],
      \ ['Abstração não é sobre imprecisão, é sobre ser preciso em um novo nível semântico.', '', '- Edsger W. Dijkstra'],
      \ ["dd é horrível de propósito. É uma piada sobre OS360 JCL. Mas hoje é uma piada padronizada internacionalmente. Eu acho que isso diz tudo.", '', '- Rob Pike'],
      \ ['Todos os loops são infinitos para módulos de RAM com defeito.'],
      \ ['Todos os idiomas devem ser aprendidos. Bons idiomas só precisam ser aprendidos uma vez.', '', '- Alan Cooper'],
      \ ['Para uma tecnologia bem-sucedida, a realidade deve ter precedência sobre as relações públicas, pois a Natureza não pode ser enganada.', '', '- Richard Feynman'],
      \ ['Se os programadores fossem eletricistas, os programadores paralelos seriam especialistas em desarmamento de bombas. Ambos cortam fios.', '', '- Bartosz Milewski'],
      \ ['Os computadores são mais difíceis de manter em grandes altitudes. Ar mais fino significa menos amortecimento entre as cabeças dos discos e os pratos. Também mais radiação.'],
      \ ['Quase toda linguagem de programação é superestimada por seus praticantes.', '', '- Larry Wall'],
      \ ['Algoritmos sofisticados são lentos quando n é pequeno e geralmente é pequeno.', '', '- Rob Pike'],
      \ ['Os métodos são apenas funções com um primeiro argumento especial.', '', '- Andrew Gerrand'],
      \
      \ ['Preocupe-se com o seu ofício.', '', 'Por que passar a vida desenvolvendo software a menos que você se preocupe em fazê-lo bem?'],
      \ ["Forneça opções, não dê desculpas esfarrapadas.", '', "Em vez de desculpas, forneça opções. Não diga que não pode ser feito; explicar o que pode ser feito."],
      \ ['Seja um catalisador para a mudança.', '', "Você não pode forçar a mudança nas pessoas. Em vez disso, mostre a eles como o futuro pode ser e ajude-os a participar da criação."],
      \ ['Faça da qualidade uma questão de requisitos.', '', "Envolva seus usuários na determinação dos requisitos reais de qualidade do projeto."],
      \ ['Analise criticamente o que você lê e ouve.', '', "Não se deixe influenciar por fornecedores, exageros da mídia ou dogmas. Analise as informações em relação a você e ao seu projeto."],
      \ ["DRY - Não se repita.", '', 'Cada fragmento de conhecimento deve ter uma representação única, inequívoca e autoritária dentro de um sistema.'],
      \ ['Elimine efeitos entre coisas não relacionadas.', '', 'Componentes de design que são autossuficientes, independentes e têm uma finalidade única e bem definida.'],
      \ ['Use tracer bullets to find the target.', '', 'Tracer bullets let you home in on your target by trying things and seeing how close they land.'],
      \ ['Programa próximo ao domínio do problema.', '', "Desenhe e codifique no idioma do seu usuário."],
      \ ['Repita a programação com o código.', '', 'Use a experiência adquirida ao implementar para refinar as escalas de tempo do projeto.'],
      \ ['Use o poder dos shells de comando.', '', "Use o shell quando as interfaces gráficas do usuário não o cortarem."],
      \ ['Sempre use o controle de código-fonte.', '', 'O controle do código-fonte é uma máquina do tempo para o seu trabalho - você pode voltar.'],
      \ ["Não entre em pânico ao depurar", '', 'Respire fundo e PENSE sobre o que poderia estar causando o bug.'],
      \ ["Não assuma - prove.", '', 'Prove suas suposições no ambiente real - com dados reais e condições de contorno.'],
      \ ['Escreva código que escreve código.', '', 'Os geradores de código aumentam sua produtividade e ajudam a evitar a duplicação.'],
      \ ['Projeto com contratos.', '', 'Use contratos para documentar e verificar se o código faz nem mais nem menos do que afirma fazer.'],
      \ ['Use asserções para evitar o impossível.', '', 'Asserções validam suas suposições. Use-os para proteger seu código de um mundo incerto.'],
      \ ['Termine o que você começou.', '', 'Sempre que possível, a rotina ou objeto que aloca um recurso deve ser responsável por desalocá-lo.'],
      \ ["Configure, não integre.", '', 'Implemente opções de tecnologia para um aplicativo como opções de configuração, não por meio de integração ou engenharia.'],
      \ ['Analise o fluxo de trabalho para melhorar a simultaneidade.', '', "Explore a simultaneidade no fluxo de trabalho do usuário."],
      \ ['Sempre projete para simultaneidade.', '', "Permita a simultaneidade e você projetará interfaces mais limpas com menos suposições."],
      \ ['Use quadros-negros para coordenar o fluxo de trabalho.', '', 'Use lousas para coordenar fatos e agentes díspares, mantendo a independência e o isolamento entre os participantes.'],
      \ ['Estime a ordem de seus algoritmos.', '', 'Tenha uma ideia de quanto tempo as coisas provavelmente levarão antes de escrever o código.'],
      \ ['Refatorar cedo, refatorar frequentemente.', '', 'Assim como você pode remover ervas daninhas e reorganizar um jardim, reescrever, retrabalhar e reprojetar o código quando necessário. Corrija a raiz do problema.'],
      \ ['Teste seu software ou seus usuários o farão.', '', "Teste impiedosamente. Não faça seus usuários encontrarem bugs para você."],
      \ ["Não reúna requisitos - procure por eles.", '', "Os requisitos raramente estão na superfície. Eles estão enterrados sob camadas de suposições, equívocos e política."],
      \ ['As abstrações vivem mais que os detalhes.', '', 'Invista na abstração, não na implementação. As abstrações podem sobreviver à barragem de mudanças de diferentes implementações e novas tecnologias.'],
      \ ["Não pense fora da caixa - encontre a caixa.", '', 'Diante de um problema impossível, identifique as restrições reais. Pergunte a si mesmo: "Tem que ser feito dessa maneira? Tem que ser feito de alguma forma?"'],
      \ ['Algumas coisas são melhor feitas do que descritas.', '', "Don't fall into the specification spiral - at some point you need to start coding."],
      \ ["Ferramentas caras não produzem designs melhores.", '', 'Cuidado com o hype do fornecedor, o dogma da indústria e a aura da etiqueta de preço. Julgue as ferramentas por seus méritos.'],
      \ ["Não use procedimentos manuais.", '', 'Um script de shell ou arquivo em lote executará as mesmas instruções, na mesma ordem, várias vezes.'],
      \ ["A codificação não é concluída até que todos os testes sejam executados.", '', "'Nuff disse."],
      \ ['Teste a cobertura do estado, não a cobertura do código.', '', "Identifique e teste estados significativos do programa. Apenas testar linhas de código não é suficiente."],
      \ ['Português é apenas uma linguagem de programação.', '', 'Escreva documentos como escreveria código: respeite o princípio DRY, use metadados, MVC, geração automática e assim por diante.'],
      \ ["Exceda suavemente as expectativas de seus usuários.", '', "Venha entender as expectativas de seus usuários e, em seguida, entregue um pouco mais."],
      \ ['Pense no seu trabalho.', '', 'Desligue o piloto automático e assuma o controle. Constantemente critique e avalie seu trabalho.'],
      \ ["Não viva com janelas quebradas.", '', 'Corrija designs ruins, decisões erradas e código ruim quando você os vir.'],
      \ ['Lembre-se do quadro geral.', '', "Não fique tão envolvido nos detalhes que você se esqueça de verificar o que está acontecendo ao seu redor."],
      \ ['Invista regularmente em sua carteira de conhecimento.', '', 'Faça do aprendizado um hábito.'],
      \ ["É tanto o que você diz quanto a maneira como você diz.", '', "Não adianta ter grandes ideias se você não as comunicar de forma eficaz."],
      \ ['Facilite a reutilização.', '', "Se for fácil de reutilizar, as pessoas o farão. Crie um ambiente que ofereça suporte à reutilização."],
      \ ['Não há decisões finais.', '', 'Nenhuma decisão está gravada em pedra. Em vez disso, considere cada um como sendo escrito na areia da praia e planeje a mudança.'],
      \ ['Protótipo para aprender.', '', 'A prototipagem é uma experiência de aprendizagem. Seu valor não está no código que você produz, mas nas lições que você aprende.'],
      \ ['Estime para evitar surpresas.', '', "Estime antes de começar. Você identificará possíveis problemas antecipadamente."],
      \ ['Mantenha o conhecimento em texto simples.', '', "O texto simples não se tornará obsoleto. Ele ajuda a alavancar seu trabalho e simplifica a depuração e o teste."],
      \ ['Use bem um único editor.', '', 'O editor deve ser uma extensão da sua mão; Certifique-se de que seu editor seja configurável, extensível e programável.'],
      \ ['Corrija o problema, não a culpa.', '', "Realmente não importa se o bug é sua culpa ou de outra pessoa - ainda é seu problema, e ainda precisa ser corrigido."],
      \ ["\"select\" não está quebrado.", '', 'É raro encontrar um bug no sistema operacional ou no compilador, ou mesmo em um produto ou biblioteca de terceiros. O bug é mais provável no aplicativo.'],
      \ ['Aprenda uma linguagem de manipulação de texto.', '', 'Você passa grande parte de cada dia trabalhando com texto. Por que não fazer com que o computador faça um pouco disso por você?'],
      \ ["Você não pode escrever um software perfeito.", '', "O software não pode ser perfeito. Proteja seu código e seus usuários contra os erros inevitáveis."],
      \ ['Quebre cedo.', '', 'Um programa morto normalmente causa muito menos danos do que um aleijado.'],
      \ ['Usar exceções para problemas excepcionais.', '', 'As exceções podem sofrer de todos os problemas de legibilidade e manutenção do código espaguete clássico. Reserve exceções para coisas excepcionais.'],
      \ ['Minimize o acoplamento entre módulos.', '', 'Evite acoplamentos escrevendo código "tímido" e aplicando a Lei de Deméter.'],
      \ ['Coloque abstrações no código, detalhes em metadados.', '', 'Programe para o caso geral e coloque as especificidades fora da base de código compilada.'],
      \ ['Projete utilizando serviços.', '', 'Projete em termos de objetos simultâneos independentes de serviços por trás de interfaces consistentes e bem definidas.'],
      \ ['Separe os modos de exibição dos modelos.', '', 'Obtenha flexibilidade a baixo custo projetando seu aplicativo em termos de modelos e visualizações.'],
      \ ["Não programe por coincidência.", '', "Confie apenas em coisas confiáveis. Cuidado com a complexidade acidental e não confunda uma feliz coincidência com um plano proposital.."],
      \ ['Teste suas estimativas.', '', "A análise matemática de algoritmos não diz tudo. Tente cronometrar seu código em seu ambiente de destino."],
      \ ['Projete para testar.', '', 'Comece a pensar em testar antes de escrever uma linha de código.'],
      \ ["Não use o código do wizard que você não entende.", '', 'Wizards pode gerar resmas de código. Certifique-se de entender tudo isso antes de incorporá-lo ao seu projeto.'],
      \ ['Trabalhe com um usuário para pensar como um usuário.', '', "É a melhor maneira de obter informações sobre como o sistema realmente será usado."],
      \ ['Use um glossário de projeto.', '', 'Crie e mantenha uma única fonte de todos os termos e vocabulário específicos para um projeto.'],
      \ ["Comece quando estiver pronto.", '', "Você tem construído experiência toda a sua vida. Não ignore as dúvidas."],
      \ ["Não seja escravo de métodos formais.", '', "Não adote cegamente nenhuma técnica sem colocá-la no contexto de suas práticas e capacidades de desenvolvimento."],
      \ ['Organize as equipes em torno da funcionalidade.', '', "Não separe designers de codificadores, testadores de modeladores de dados. Crie equipes da maneira como você cria código."],
      \ ['Teste cedo. Teste com frequência. Teste automaticamente.', '', 'Os testes executados com cada compilação são muito mais eficazes do que os planos de teste que ficam em uma prateleira.'],
      \ ['Use sabotadores para testar seus testes.', '', 'Introduza bugs de propósito em uma cópia separada da fonte para verificar se o teste os detectará.'],
      \ ['Encontre bugs uma vez.', '', 'Uma vez que um testador humano encontra um bug, deve ser a última vez que um testador humano encontra esse bug. Testes automáticos devem verificar a partir de então.'],
      \ ['Assine seu trabalho.', '', 'Artesãos de uma idade anterior tinham orgulho de assinar seu trabalho. Você também deveria ser.'],
      \ ['Pense duas vezes, codifique uma vez.'],
      \ ['Não importa o quão longe você tenha ido na estrada errada, volte agora.'],
      \ ['Por que nunca temos tempo para fazer isso direito, mas sempre temos tempo para fazê-lo de novo?'],
      \ ['Semanas de programação podem economizar horas de planejamento.'],
      \ ['Iterar é humano, recursar é divino.', '', '- L. Peter Deutsch'],
      \ ['Os computadores são inúteis. Eles só podem lhe dar respostas.', '', '- Pablo Picasso'],
      \ ['A questão de saber se os computadores podem pensar é como a questão de saber se os submarinos podem nadar.', '', '- Edsger W. Dijkstra'],
      \ ["É ridículo viver 100 anos e só ser capaz de se lembrar de 30 milhões de bytes. Você sabe, menos do que um CD. A condição humana está realmente se tornando mais obsoleta a cada minuto.", '', '- Marvin Minsky'],
      \ ["The city's central computer told you? R2D2, you know better than to trust a strange computer!", '', '- C3PO'],
      \ ['A maioria dos softwares hoje é muito parecida com uma pirâmide egípcia com milhões de tijolos empilhados uns sobre os outros, sem integridade estrutural, mas apenas feitos pela força bruta e milhares de escravos.', '', '- Alan Kay'],
      \ ["Eu finalmente aprendi o que \"compatível para cima\" significa. Isso significa que podemos manter todos os nossos velhos erros.", '', '- Dennie van Tassel'],
      \ ["Existem dois produtos principais que saem de Berkeley: LSD e UNIX. Não acreditamos que isso seja uma coincidência.", '', '- Jeremy S. Anderson'],
      \ ["A maior parte de todas as patentes são uma porcaria. Gastar tempo lendo-os é estúpido. Cabe ao proprietário da patente fazê-lo e aplicá-los.", '', '- Linus Torvalds'],
      \ ['Controlar a complexidade é a essência da programação de computadores.', '', '- Brian Kernighan'],
      \ ['A complexidade mata. Ele suga a vida dos desenvolvedores, dificulta o planejamento, a criação e o teste de produtos, introduz desafios de segurança e causa frustração do usuário final e do administrador.', '', '- Ray Ozzie'],
      \ ['A função de um bom software é fazer com que o complexo pareça simples.', '', '- Grady Booch'],
      \ ["Há uma velha história sobre a pessoa que desejava que seu computador fosse tão fácil de usar quanto seu telefone. Esse desejo se tornou realidade, já que não sei mais como usar meu telefone.", '', '- Bjarne Stroustrup'],
      \ ['Existem apenas duas indústrias que se referem aos seus clientes como "usuários".', '', '- Edward Tufte'],
      \ ['A maioria de vocês está familiarizada com as virtudes de um programador. Há três, é claro: preguiça, impaciência e arrogância.', '', '- Larry Wall'],
      \ ['A educação em ciência da computação não pode fazer de ninguém um programador experiente, assim como estudar pincéis e pigmentos pode fazer de alguém um pintor experiente.', '', '- Eric S. Raymond'],
      \ ['O otimismo é um risco ocupacional da programação; feedback é o tratamento.', '', '- Kent Beck'],
      \ ['Primeiro, resolva o problema. Em seguida, escreva o código.', '', '- John Johnson'],
      \ ['Medir o progresso da programação por linhas de código é como medir o progresso da construção de aeronaves por peso.', '', '- Bill Gates'],
      \ ["Não se preocupe se não funcionar direito. Se tudo acontecesse, você estaria sem emprego.", '', "- Mosher's Law of Software Engineering"],
      \ ['Um programador LISP sabe o valor de tudo, mas o custo de nada.', '', '- Alan J. Perlis'],
      \ ['Todos os problemas em ciência da computação podem ser resolvidos com outro nível de indireção.', '', '- David Wheeler'],
      \ ['Funções atrasam a vinculação; as estruturas de dados induzem a ligação. Moral: Estrutura os dados no final do processo de programação.', '', '- Alan J. Perlis'],
      \ ['As coisas devem ser fáceis e as coisas difíceis devem ser possíveis.', '', '- Larry Wall'],
      \ ['Nada é mais permanente do que uma solução temporária.'],
      \ ["Se você não pode explicar algo para uma criança de seis anos, você realmente não entende por si mesmo.", '', '- Albert Einstein'],
      \ ['Toda programação é um exercício de cache.', '', '- Terje Mathisen'],
      \ ['Software é difícil.', '', '- Donald Knuth'],
      \ ['Eles não sabiam que era impossível, então eles fizeram isso!', '', '- Mark Twain'],
      \ ['O modelo orientado a objetos facilita a criação de programas por acreção. O que isso geralmente significa, na prática, é que ele fornece uma maneira estruturada de escrever código espaguete.', '', '- Paul Graham'],
      \ ['Pergunta: Como um grande projeto de software chega a um ano de atraso?', 'Resposta: Um dia de cada vez!'],
      \ ['Os primeiros 90% do código representam os primeiros 90% do tempo de desenvolvimento. Os 10% restantes do código representam os outros 90% do tempo de desenvolvimento.', '', '- Tom Cargill'],
      \ ["Em software, raramente temos requisitos significativos. Mesmo que o façamos, a única medida de sucesso que importa é se a nossa solução resolve a ideia mutável do cliente de qual é o seu problema.", '', '- Jeff Atwood'],
      \ ['Se a depuração é o processo de remoção de bugs, então a programação deve ser o processo de colocá-los.', '', '- Edsger W. Dijkstra'],
      \ ['640K deve ser suficiente para qualquer um.', '', '- Bill Gates, 1981'],
      \ ['Para entender a recursão, é preciso primeiro entender a recursão.', '', '- Stephen Hawking'],
      \ ['Desenvolver tolerância à imperfeição é o fator-chave para transformar iniciantes crônicos em finalizadores consistentes.', '', '- Jon Acuff'],
      \ ['Todo grande desenvolvedor que você conhece chegou lá resolvendo problemas que eles não estavam qualificados para resolver até que eles realmente o fizessem.', '', '- Patrick McKenzie'],
      \ ["O usuário médio não dá a mínima para o que acontece, desde que (1) funcione e (2) seja rápido.", '', '- Daniel J. Bernstein'],
      \ ['Andar sobre a água e desenvolver software a partir de uma especificação são fáceis se ambos estiverem congelados.', '', '- Edward V. Berard'],
      \ ['Seja curioso. Leia amplamente. Tente coisas novas. Acho que muito do que as pessoas chamam de inteligência se resume à curiosidade.', '', '- Aaron Swartz'],
      \ ['O que um programador pode fazer em um mês, dois programadores podem fazer em dois meses.', '', '- Frederick P. Brooks'],
      \ ]

let g:startify_custom_header_quotes = exists('g:startify_custom_header_quotes')
      \ ? g:startify_custom_header_quotes
      \ : startify#fortune#predefined_quotes()
