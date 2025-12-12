"""Définition du graphe de l'agent."""

from langchain_google_genai import ChatGoogleGenerativeAI
from langgraph.graph import START, StateGraph
from langgraph.prebuilt import ToolNode, tools_condition

from src.agent.state import AgentState
from src.agent.tools.locations import (
    search_location_by_id_tool,
    search_location_nearest_tool,
    search_locations_by_keyword_tool,
)
from src.config.env import settings

# 1. Initialiser le modèle
# Utilisation de gemini-1.5-flash pour un bon compromis vitesse/coût
llm = ChatGoogleGenerativeAI(
    model="gemini-2.5-flash-lite",
    google_api_key=settings.GOOGLE_API_KEY,
    temperature=0,
)

# 2. Définir les outils
location_tools = [
    search_locations_by_keyword_tool,
    search_location_by_id_tool,
    search_location_nearest_tool,
]

# 3. Lier les outils au modèle
llm_with_tools = llm.bind_tools(location_tools)


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

builder.add_node("agent_planning", agent_node)
builder.add_node("tools", ToolNode(location_tools))

builder.add_edge(START, "agent_planning")

# Condition pour aller vers les outils ou terminer
builder.add_conditional_edges(
    "agent_planning",
    tools_condition,
)

builder.add_edge("tools", "agent_planning")

# 6. Compiler le graphe
graph = builder.compile()
