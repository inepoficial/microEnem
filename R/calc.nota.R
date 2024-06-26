#' @title Calcula nota do Enem
#' @description Calcula a nota de um sujeito na escala do Enem (500, 100).
#'
#' @param resps vetor de respostas de um ou mais sujeitos. O
#' vetor deve ser no mesmo formato da variável TX_RESPOSTAS
#' dos microdados do Enem.
#'
#' É importante destacar que desde 2010 os cadernos de Linguagens
#' e Códigos têm cinco itens de língua inglesa e cinco itens
#' de língua espanhola, por isso esses cadernos possuem 50 questões.
#'
#' Em algumas edições de microdados, o vetor de respostas da variável
#' TX_RESPOSTAS_LC possui 50 caracteres e em outros, 45. Em 2019,
#' o vetor possui 50 caracteres e em 2022, 45. Em ambos os casos,
#' o vetor contém somente a resposta do sujeito à língua
#' estrangeira selecionada no momento da inscrição. No caso do
#' vetor com 50 caracteres, as respostas aos cinco itens da outra
#' língua são marcados com `9`. A função `calc.nota`
#' transforma internamente essa resposta `9` em `NA` e esses itens
#' não são considerados para o cálculo da nota do sujeito.
#'
#' @param codigo código da prova disponível no dicionário dos
#' microdados. Essa informação também está disponível no
#' objeto `dic.cad` deste pacote
#'
#' @param lingua vetor com indicação da língua estrangeira escolhida
#' pela pessoa. Essa informação corresponde à variável `TP_LINGUA`
#' nos microdados (`0` para inglês, `1` para espanhol). Só é necessário
#' para o ano de 2022.
#'
#' @details A nota é calculada pelo método Expected a
#' posteriori (EAP), com 40 pontos de quadratura de -4 a 4.
#' A média da distribuição priori é 0 e o desvio padrão, 1. No
#' Enem as notas estão em uma escala com média 500 e desvio padrão
#' 100. A referência dessa escala são os concluintes regulares de
#' escola pública do Enem 2009. Ou seja, a média desses alunos
#' no Enem 2009 foi 500 e o desvio padrão, 100.
#'
#' Os parâmetros dos itens estão divulgados em uma escala com
#' média 0 e desvio padrão 1. A referência dessa escala é a
#' amostra utilizada na primeira calibração dos itens do Enem,
#' em 2009. Para posicionar os parâmetros na escala oficial
#' do Enem, aplicamos as seguintes equações de
#' transformação:
#' \deqn{a_{enem} = \frac{a_{01}}{s}}
#' \deqn{b_{enem} = b_{01}*s+m}
#' \deqn{c_{enem} = c_{01}}
#' Onde \eqn{a_{enem}}, \eqn{b_{enem}} e \eqn{c_{enem}} são os
#' parâmetros dos itens na escala oficial do Enem,
#' \eqn{a_{01}}, \eqn{b_{01}} e \eqn{c_{01}} são os parâmetros
#' dos itens divulgados nos microdados, e `k` e `d` são as
#' constantes de transformação da escala dos parâmetros divulgados
#' para a escala oficial. Essas constantes estão disponibilizadas
#' no objeto `constantes` deste pacote.
#'
#' @return as notas na escala oficial do Enem
#'
#' @examples
#' # importar primeiros 100 casos dos microdados de 2022
#' # (é preciso direcionar para a pasta onde o arquivo se localiza)
#' micro <- data.table::fread('D:/Microdados/Enem/MICRODADOS_ENEM_2022.csv', nrows = 100)
#'
#' # selecionar os casos do caderno 1065 (LC)
#' resp <- subset(micro, micro$CO_PROVA_LC == 1065)
#'
#' # calcular a nota
#' nota <- calc.nota(resps = resp$TX_RESPOSTAS_LC, codigo = 1065, lingua = resp$TP_LINGUA)
#' nota
#'
#' # comparar com a nota oficial
#' all.equal(resp$NU_NOTA_LC, nota)
#'
#' # calcular a nota de um sujeito que não está nos microdados
#' # vetor de resposta de uma pessoa fictícia que respondeu o caderno 1065 de LC em 2022 (45 caracteres)
#' resp <- c('BBDABBDBAADCBABBADAACBDDDDEACACBCACAABBBECBEC')
#'
#' # calcular a nota
#' nota <- calc.nota(resp, codigo = 1065, lingua = 0)
#' nota
#'
#' # vetor de resposta de uma pessoa fictícia que respondeu o caderno 511 de LC em 2019 (50 caracteres)
#' resp <- c('99999BBDABBDBAADCBABBADAACBDDDDEACACBCACAABBBECBEC')
#'
#' # calcular a nota
#' nota <- calc.nota(resp, codigo = 511)
#' nota
#' @export


calc.nota <- function(
  resps,
  codigo = NULL,
  lingua = NULL
){

  # modelo mirt do caderno
  mod <- mod.caderno(codigo = codigo)

  # gabarito do caderno
  key <- subset(itens, CO_PROVA == codigo)
  key <- dplyr::arrange(key, TP_LINGUA, CO_POSICAO)

  # abrir o vetor de respostas
  resp <- abre.resp(resps)

  # verificar se algum item foi anulado
  anulado <- which(key$IN_ITEM_ABAN == 1)
  key <- subset(key, IN_ITEM_ABAN == 0)

  # área e ano do caderno
  area <- dic.cad[dic.cad$codigo == codigo, 'area']
  ano <- dic.cad[dic.cad$codigo == codigo, 'ano']

  # transformar 9 em NA nos itens de língua estrangeira
  if (area == 'LC' & ano != 2009)
  {
    resp <- apply(resp, 2, \(x)ifelse(x == '9', NA, x))

    if (ano == 2022)
      if(ncol(resp) != 45)
      {stop(paste0('Para o ano de ', ano, ', o vetor de resposta deve ter 45 elementos.'))} else {resp <- insereNA(data = resp, lingua = lingua)}
  }

  # retirar o item anulado da resposta
  if (length(anulado) > 0)
    if(length(resps) > 1)
    {resp <- resp[,-anulado]} else {resp <- t(data.frame(resp[-anulado]))}


  # # verificar se o tamanho da prova é igual ao tamanho do vetor de respostas
  # if(ncol(resp) != length(key$TX_GABARITO))
  #   stop(paste0('O vetor de resposta deve ser do mesmo tamanho da prova. O vetor de respostas possui ',
  #               ncol(resp), ' caracteres e a prova possui ',
  #               length(key$TX_GABARITO),
  #               ' itens.'))

  # corrigir as respostas
  resp <- mirt::key2binary(resp, key$TX_GABARITO)

  # calcular a nota
  nota <- data.frame(mirt::fscores(mod, response.pattern = resp, quadpts = 40, theta_lim = c(-4,4)))$F1

  # transformação da escala
  nota <- round(nota*constantes[constantes$area == area, 'k'] + constantes[constantes$area == area, 'd'], 1)

  # quem entregou a prova em branco recebe 0
  branco <- stringr::str_count(resps, "\\.")
  nota[(branco == 45)] <- 0

  return(nota)

}
