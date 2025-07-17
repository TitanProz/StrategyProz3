import OpenAI from 'openai';

const openai = new OpenAI({
  apiKey: import.meta.env.VITE_OPENAI_API_KEY,
  baseURL: 'https://api.openai.com/v1',
  dangerouslyAllowBrowser: true
});

export async function analyzeResponses(
  responses: Record<string, string>,
  selectedPractice?: string,
  moduleSlug?: string
) {
  try {
    const validResponses = Object.values(responses)
      .filter((r) => r && r.trim())
      .map((r) => r.trim());

    if (validResponses.length === 0) {
      validResponses.push("No responses provided yet.");
    }

    let prompt: string;

    switch (moduleSlug) {
      case 'capabilities-inventory':
        if (selectedPractice) {
          prompt = `You are an AI. The user provided these answers:
${validResponses.join('\n\n')}

The user has selected "${selectedPractice}" as their consulting practice.

Generate a JSON with:
"practices": an array with just the selected practice
"niches": an array of 5 specific niche options within "${selectedPractice}" that the user may want to consider

Example format:
{
"practices": ["${selectedPractice}"],
"niches": ["Niche 1", "Niche 2", "Niche 3", "Niche 4", "Niche 5"]
}
`;
        } else {
          prompt = `You are an AI. The user provided these answers:
${validResponses.join('\n\n')}

Generate a JSON with:
"practices": an array of exactly 5 consulting practice types that best suit their capabilities
"niches": an empty array for now (we'll fill this later when they select a practice)

Example format:
{
"practices": ["Practice 1", "Practice 2", "Practice 3", "Practice 4", "Practice 5"],
"niches": []
}
`;
        }
        break;

      case 'strategy-framework':
        prompt = `You are an AI. The user provided these answers:
${validResponses.join('\n\n')}

Generate a JSON with:
{
"valuePropositions": [
"Example Value Proposition #1",
"Example Value Proposition #2",
"Example Value Proposition #3",
"Example Value Proposition #4",
"Example Value Proposition #5"
],
"targetIndustries": [
"Industry #1",
"Industry #2",
"Industry #3",
"Industry #4",
"Industry #5"
],
"idealClients": [
"Detailed Ideal Client #1 - include characteristics, challenges, and decision-making profile",
"Detailed Ideal Client #2 ...",
"Detailed Ideal Client #3 ...",
"Detailed Ideal Client #4 ...",
"Detailed Ideal Client #5 ..."
]
}

Ensure there are exactly 5 items in each array, describing each in detail.
`;
        break;

      case 'opportunity-map':
        prompt = `You are an AI. The user provided these answers:
${validResponses.join('\n\n')}

Generate a JSON object with two arrays:
{
"opportunityMapServices": [
  {
    "serviceName": "Service 1",
    "topIndustries": ["Industry A", "Industry B", "Industry C", "Industry D", "Industry E"],
    "whyGoodTarget": ["Reason 1 for Industry A", "Reason 2", "Reason 3", "Reason 4", "Reason 5"],
    "risks": ["Potential Risk 1", "Potential Risk 2", "Potential Risk 3", "Potential Risk 4", "Potential Risk 5"]
  },
  {
    "serviceName": "Service 2",
    "topIndustries": ["Industry F", "Industry G", "Industry H", "Industry I", "Industry J"],
    "whyGoodTarget": ["Reason 1", "Reason 2", "Reason 3", "Reason 4", "Reason 5"],
    "risks": ["Potential Risk 1", "Potential Risk 2", "Potential Risk 3", "Potential Risk 4", "Potential Risk 5"]
  }
],
"opportunityMapIndustries": [
  {
    "industryName": "Industry A",
    "services": ["Service 1", "Service 2", "Service 3"],
    "whyServiceFits": ["Reason 1", "Reason 2", "Reason 3"],
    "risks": ["Risk 1", "Risk 2", "Risk 3"]
  },
  {
    "industryName": "Industry B",
    "services": ["Service 4", "Service 5", "Service 6"],
    "whyServiceFits": ["Reason 1", "Reason 2", "Reason 3"],
    "risks": ["Risk 1", "Risk 2", "Risk 3"]
  }
]
}

Each array should have at least 2 objects, each with top five industries or services, reasons, and risks, based on the user's responses.
`;
        break;

      case 'service-offering':
        prompt = `You are an AI. The user provided these answers:
${validResponses.join('\n\n')}

Generate a JSON object with a "serviceTiers" array. Exactly 3 items (Basic, Mid-Level, Premium).
Each item in "serviceTiers" must have:
{
  "name": "Basic" (or "Mid-Level" or "Premium"),
  "features": "The key features and benefits of this tier",
  "outcomes": "The client outcomes this tier should produce",
  "intangibleBenefits": "Any intangible or non-obvious benefits for this tier"
}
Example:
{
"serviceTiers": [
  {
    "name": "Basic",
    "features": "...",
    "outcomes": "...",
    "intangibleBenefits": "..."
  },
  ...
]
}
`;
        break;

      case 'positioning':
        prompt = `You are an AI. The user provided these answers:
${validResponses.join('\n\n')}

Generate a JSON object with the following structure:
{
"topNiches": [
  {
    "niche": "Niche 1",
    "positioning": "Explanation of how to stand out in Niche 1"
  },
  {
    "niche": "Niche 2",
    "positioning": "..."
  },
  {
    "niche": "Niche 3",
    "positioning": "..."
  },
  {
    "niche": "Niche 4",
    "positioning": "..."
  },
  {
    "niche": "Niche 5",
    "positioning": "..."
  }
],
"risksObstacles": [
  "Risk or obstacle #1",
  "Risk or obstacle #2",
  "Risk or obstacle #3",
  "Risk or obstacle #4",
  "Risk or obstacle #5"
],
"strategies": [
  "Actionable Strategy #1 (very specific steps)",
  "Actionable Strategy #2 (very specific steps)",
  "Actionable Strategy #3 (very specific steps)",
  "Actionable Strategy #4 (very specific steps)",
  "Actionable Strategy #5 (very specific steps)"
],
"opportunityMatrix": [
  {
    "service": "Service name 1",
    "segment": "Potential client segment",
    "demand": "High/Medium/Low",
    "easeOfEntry": "High/Medium/Low",
    "profitability": "High/Medium/Low",
    "risks": ["Risk A", "Risk B"],
    "recommendedStrategies": ["Strategy A", "Strategy B"]
  },
  {
    "service": "Service name 2",
    "segment": "Potential client segment",
    "demand": "High/Medium/Low",
    "easeOfEntry": "High/Medium/Low",
    "profitability": "High/Medium/Low",
    "risks": ["Risk A", "Risk B"],
    "recommendedStrategies": ["Strategy A", "Strategy B"]
  }
]
}

Ensure exactly 5 top niches.
"risksObstacles" should reflect obstacles or limitations the user might face.
"strategies" must be extremely specific and actionable, providing direct steps or recommendations the user can implement.
"opportunityMatrix" shows how each service intersects with potential client segments (demand, entry, profitability), plus potential risks and recommended strategies.
`;
        break;

      case 'pricing':
        prompt = `You are an AI. The user has completed the "Pricing Strategy Planner" module with these answers:
${validResponses.join('\n\n')}

Generate a JSON object with the following fields based on the user's responses:
{
"marketRates": "Typical market rates for each service you plan to provide",
"justification": "The justification for the pricing and Return-On-Investment",
"benefits": "Clear statements of the transformational benefits you offer and how you set yourself apart from competitors",
"testimonials": "Any testimonials or quantitative success data that reinforce the premium value of your approach",
"pricingAdjustments": "How you plan to adjust pricing for different project scopes or client budgets",
"futurePricing": "Your ideas about package add-ons, retainer upgrades, or future services that might change your pricing model over time",
"revenueTargets": "What revenue targets or client acquisition goals you have in mind, which may help determine baseline pricing and future adjustments",
"constraints": "Any constraints or cost structures (operational expenses, desired profit margins) that influence your pricing strategy",
"milestones": "Details on milestones you're aiming for (e.g., after acquiring a certain number of clients, after receiving specific client feedback, or once you've established a track record of successes)",
"tracking": "How you currently track performance and profitability in your engagements"
}

Ensure each field is a detailed string response tailored to the user's answers.
`;
        break;

      case 'final-report':
        prompt = `You are an AI. The user has completed all modules, and these are their answers from all previous modules:
${validResponses.join('\n\n')}

Generate a comprehensive JSON final report that synthesizes all previous responses into a cohesive consulting strategy. Include the following sections:

{
"executiveSummary": {
  "overview": "A brief summary of the consulting strategy",
  "keyStrategies": ["Strategy 1", "Strategy 2", "Strategy 3"],
  "vision": "The long-term vision for the consulting practice"
},
"marketAnalysis": {
  "targetMarket": "Description of the target market",
  "competitiveLandscape": "Analysis of competitors",
  "opportunities": ["Opportunity 1", "Opportunity 2", "Opportunity 3"],
  "threats": ["Threat 1", "Threat 2", "Threat 3"]
},
"serviceStrategy": {
  "coreServices": ["Service 1", "Service 2", "Service 3"],
  "valueProposition": "The unique value offered to clients",
  "deliveryModel": "How services will be delivered",
  "differentiators": ["Differentiator 1", "Differentiator 2", "Differentiator 3"]
},
"pricingModel": {
  "structure": "Description of pricing structure",
  "rates": "Typical rates for services",
  "packages": ["Package 1", "Package 2", "Package 3"],
  "flexibility": "How pricing adapts to different clients"
},
"implementationPlan": {
  "phases": ["Phase 1", "Phase 2", "Phase 3"],
  "timeline": "Estimated timeline for implementation",
  "milestones": ["Milestone 1", "Milestone 2", "Milestone 3"],
  "resources": ["Resource 1", "Resource 2", "Resource 3"]
},
"riskAssessment": {
  "businessRisks": ["Risk 1", "Risk 2", "Risk 3"],
  "mitigationStrategies": ["Strategy 1", "Strategy 2", "Strategy 3"],
  "contingencyPlans": ["Plan 1", "Plan 2", "Plan 3"]
},
"successMetrics": {
  "kpis": ["KPI 1", "KPI 2", "KPI 3"],
  "targets": "Specific targets for success",
  "evaluationMethod": "How success will be measured",
  "reviewProcess": "Process for reviewing progress"
}
}

Tailor each section to the user's responses, providing detailed and actionable insights.
`;
        break;

      default:
        prompt = `You are an AI. The user provided these answers:
${validResponses.join('\n\n')}

Generate a JSON analysis based on the responses for the module "${moduleSlug || 'unknown'}".
Provide relevant insights in a structured format appropriate to the module's purpose.
If no specific module is identified, provide a general summary of the responses.
`;
    }

    const completion = await openai.chat.completions.create({
      model: 'o4-mini',
      messages: [{ role: 'user', content: prompt }],
      response_format: { type: 'json_object' }
    });

    const result = JSON.parse(completion.choices[0].message.content || '{}');
    return result;
  } catch (error: any) {
    console.error('OpenAI API error:', error);
    throw new Error('Failed to analyze responses: ' + error.message);
  }
}