"""Définition du graphe de l'agent."""

from langchain_openai import ChatOpenAI
from langgraph.graph import START, StateGraph
from langgraph.prebuilt import ToolNode, tools_condition

from src.agent.state import AgentState
from src.agent.tools.flights import search_flights_tool
from src.agent.tools.hotels import search_hotels_tool
from src.agent.tools.locations import (
    search_location_by_id_tool,
    search_location_nearest_tool,
    search_locations_by_keyword_tool,
)
from src.agent.tools.offers import book_offer_tool, select_offer_tool
from src.config.env import settings

# 1. Initialiser le modèle
# OVH GPT-OSS via endpoint OpenAI-compatible
llm = ChatOpenAI(
    model=settings.LLM_MODEL,
    base_url=settings.LLM_API_BASE,
    api_key=settings.LLM_API_KEY,
    temperature=0,
)

# 2. Définir les outils
tools = [
    search_locations_by_keyword_tool,
    search_location_by_id_tool,
    search_location_nearest_tool,
    search_flights_tool,
    search_hotels_tool,
    select_offer_tool,
    book_offer_tool,
]

# 3. Lier les outils au modèle
llm_with_tools = llm.bind_tools(tools)


# 4. Définir les noeuds
async def agent_node(state: AgentState):
    """Noeud principal de l'agent qui appelle le LLM."""
    messages = state["messages"]
    # On pourrait ajouter le userid dans le prompt système si nécessaire
    # userid = state.get("userid")

    response = await llm_with_tools.ainvoke(messages)
    return {"messages": [response]}


# 5. Construire le graphe
builder = StateGraph(AgentState)

builder.add_node("agent", agent_node)
builder.add_node("tools", ToolNode(tools))

builder.add_edge(START, "agent")

# Condition pour aller vers les outils ou terminer
builder.add_conditional_edges(
    "agent",
    tools_condition,
)

builder.add_edge("tools", "agent")

# 6. Compiler le graphe
graph = builder.compile()
