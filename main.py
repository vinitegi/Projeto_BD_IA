import os
import re
import sys
from pathlib import Path

import chromadb
from google import genai
from google.genai import types
from pypdf import PdfReader

PASTA_DOCS = Path("docs")
PASTA_CHROMA = "chroma_db"
COLECAO = "smartcampus_docs"
MODELO_EMBEDDING = "gemini-embedding-001"
TAMANHO_CHUNK = 800
SOBREPOSICAO = 150


# 1) Leitura dos documentos -------------------------------------------------
def ler_documento(caminho: Path) -> str:
    if caminho.suffix.lower() == ".pdf":
        leitor = PdfReader(str(caminho))
        return "\n\n".join(p.extract_text() or "" for p in leitor.pages)
    return caminho.read_text(encoding="utf-8")


# 2) Chunking: quebra o texto em trechos com sobreposicao -------------------
def dividir(texto: str, tamanho: int = TAMANHO_CHUNK, sobreposicao: int = SOBREPOSICAO) -> list[str]:
    texto = re.sub(r"\n{3,}", "\n\n", texto).strip()
    chunks, ini = [], 0
    while ini < len(texto):
        fim = min(ini + tamanho, len(texto))
        if fim < len(texto):  # tenta cortar no fim de um paragrafo, senao num espaco
            corte = texto.rfind("\n\n", ini, fim)
            if corte == -1:
                corte = texto.rfind(" ", ini, fim)
            if corte > ini + tamanho // 2:
                fim = corte
        pedaco = texto[ini:fim].strip()
        if pedaco:
            chunks.append(pedaco)
        if fim >= len(texto):
            break
        ini = max(fim - sobreposicao, ini + 1)
        while ini < len(texto) and not texto[ini].isspace():  # nao comecar no meio de palavra
            ini += 1
    return chunks


# 3) Embeddings com o Gemini ------------------------------------------------
def gerar_embeddings(textos: list[str], tarefa: str) -> list[list[float]]:
    chave = os.getenv("GEMINI_API_KEY")
    if not chave:
        sys.exit("Defina a variavel de ambiente GEMINI_API_KEY (chave gratis em aistudio.google.com/apikey)")
    cliente = genai.Client(api_key=chave)
    vetores = []
    for i in range(0, len(textos), 50):
        resp = cliente.models.embed_content(
            model=MODELO_EMBEDDING,
            contents=textos[i:i + 50],
            config=types.EmbedContentConfig(task_type=tarefa),
        )
        vetores.extend(e.values for e in resp.embeddings)
    return vetores


# 4) ChromaDB ---------------------------------------------------------------
def abrir_colecao(recriar: bool = False):
    cliente = chromadb.PersistentClient(path=PASTA_CHROMA)
    if recriar:
        try:
            cliente.delete_collection(COLECAO)
        except Exception:
            pass
    return cliente.get_or_create_collection(
        name=COLECAO,
        metadata={"hnsw:space": "cosine"},  # similaridade por cosseno
        embedding_function=None,            # nos mesmos geramos os vetores
    )


def indexar():
    arquivos = sorted(p for p in PASTA_DOCS.iterdir() if p.suffix.lower() in {".md", ".txt", ".pdf"})
    if not arquivos:
        sys.exit(f"Coloque documentos (.md, .txt ou .pdf) na pasta {PASTA_DOCS}/")

    ids, textos, metadados = [], [], []
    for arq in arquivos:
        pedacos = dividir(ler_documento(arq))
        print(f"{arq.name}: {len(pedacos)} trechos")
        for n, pedaco in enumerate(pedacos):
            ids.append(f"{arq.stem}-{n:03d}")
            textos.append(pedaco)
            metadados.append({"fonte": arq.name, "trecho": n})

    vetores = gerar_embeddings(textos, "RETRIEVAL_DOCUMENT")
    colecao = abrir_colecao(recriar=True)
    colecao.add(ids=ids, documents=textos, embeddings=vetores, metadatas=metadados)
    print(f"\nPronto: {colecao.count()} trechos gravados em {PASTA_CHROMA}/")


def buscar(pergunta: str, k: int = 3):
    colecao = abrir_colecao()
    if colecao.count() == 0:
        sys.exit("Base vazia. Rode primeiro: python base_vetorial.py indexar")
    vetor = gerar_embeddings([pergunta], "RETRIEVAL_QUERY")[0]
    res = colecao.query(query_embeddings=[vetor], n_results=k)
    for doc, meta, dist in zip(res["documents"][0], res["metadatas"][0], res["distances"][0]):
        print(f"\n--- {meta['fonte']} (trecho {meta['trecho']}) | distancia {dist:.3f}")
        print(doc)


if __name__ == "__main__":
    if len(sys.argv) >= 2 and sys.argv[1] == "indexar":
        indexar()
    elif len(sys.argv) >= 3 and sys.argv[1] == "buscar":
        buscar(" ".join(sys.argv[2:]))
    else:
        print(__doc__)