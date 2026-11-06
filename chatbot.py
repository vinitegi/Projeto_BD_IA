"""Etapa 4 - Chatbot RAG: busca trechos no ChromaDB e o Gemini responde com base neles.

Uso:  python chatbot.py
"""
import os
import sys

from google import genai
from google.genai import types

# reaproveita as funcoes da etapa 3 (o arquivo com o codigo da etapa 3 chama-se main.py)
from base_vetorial import abrir_colecao, gerar_embeddings

MODELO_CHAT = "gemini-3.8-flash"
TOP_K = 4

INSTRUCOES = """Voce e o SmartCampus, assistente academico de uma faculdade.
Responda a pergunta do aluno usando SOMENTE os trechos de documentos fornecidos na mensagem.
Regras:
- Cite o nome do documento de origem entre parenteses, por exemplo (aula-pratica-triggers.pdf).
- Se os trechos nao trouxerem a resposta, diga que nao encontrou essa informacao nos documentos. Nao invente.
- Responda em portugues do Brasil, de forma clara e curta."""


def buscar_trechos(pergunta: str, k: int = TOP_K) -> list[dict]:
    """Parte 'R' do RAG: acha no ChromaDB os trechos mais parecidos com a pergunta."""
    colecao = abrir_colecao()
    if colecao.count() == 0:
        sys.exit("Base vazia. Rode primeiro a indexacao da etapa 3.")
    vetor = gerar_embeddings([pergunta], "RETRIEVAL_QUERY")[0]
    res = colecao.query(query_embeddings=[vetor], n_results=k)
    return [
        {"fonte": meta["fonte"], "texto": doc}
        for doc, meta in zip(res["documents"][0], res["metadatas"][0])
    ]


def montar_mensagem(pergunta: str, trechos: list[dict]) -> str:
    """Parte 'A' do RAG: coloca os trechos encontrados junto com a pergunta."""
    contexto = "\n\n".join(f"[Fonte: {t['fonte']}]\n{t['texto']}" for t in trechos)
    return f"TRECHOS DOS DOCUMENTOS:\n{contexto}\n\nPERGUNTA DO ALUNO: {pergunta}"


def main():
    chave = os.getenv("GEMINI_API_KEY")
    if not chave:
        sys.exit("Defina a variavel de ambiente GEMINI_API_KEY antes de rodar.")

    cliente = genai.Client(api_key=chave)
    # chats.create guarda o historico da conversa
    chat = cliente.chats.create(
        model=MODELO_CHAT,
        config=types.GenerateContentConfig(system_instruction=INSTRUCOES, temperature=0.2),
    )

    print("SmartCampus - pergunte sobre os documentos da disciplina (digite 'sair' para encerrar)\n")
    while True:
        try:
            pergunta = input("Voce: ").strip()
        except (EOFError, KeyboardInterrupt):
            print()
            break
        if not pergunta:
            continue
        if pergunta.lower() in {"sair", "exit", "quit"}:
            break
        try:
            trechos = buscar_trechos(pergunta)                                # R: recupera
            resposta = chat.send_message(montar_mensagem(pergunta, trechos))  # A + G: aumenta e gera
            print(f"\nSmartCampus: {resposta.text}")
            print("   Fontes: " + ", ".join(sorted({t['fonte'] for t in trechos})) + "\n")
        except Exception as e:
            print(f"\n[erro] {e}\n")


if __name__ == "__main__":
    main()