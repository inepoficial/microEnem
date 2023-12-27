#' @title Abre o vetor de resposta
#' @description Abre o vetor de resposta da variável TX_RESPOSTAS dos microdados
#'
#' @param unico vetor único de respostas de um ou mais sujeitos no
#' formato da variável TX_RESPOSTAS dos microdados do Enem
#'
#' @return Um objeto de classe `matrix` em que as colunas são os itens e as
#' linhas são os sujeitos
#'
#' @examples
#'
#' # importar primeiros 100 casos dos microdados de 2019 (é preciso direcionar para a pasta onde o arquivo se localiza)
#' micro <- data.table::fread('MICRODADOS_ENEM_2019.csv', nrows = 100)
#'
#' resp <- abre.resp(micro$TX_RESPOSTAS_LC)
#' @export


abre.resp <- function (unico)
{
  resp. <- strsplit(as.character(as.matrix(unico)), NULL)
  resp <- do.call(rbind, resp.)
  return(resp)
}
