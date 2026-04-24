import boto3
import json
import os
import time

bedrock_agent_runtime = boto3.client('bedrock-agent-runtime')
bedrock_runtime = boto3.client('bedrock-runtime')

KNOWLEDGE_BASE_ID = os.environ['KNOWLEDGE_BASE_ID']
MODEL_ID = os.environ['MODEL_ID']
ALLOWED_ORIGIN = os.environ.get('ALLOWED_ORIGIN', '*')


def lambda_handler(event, context):
    """
    AI Chat handler:
      1. Retrieve relevant docs from Bedrock Knowledge Base
      2. Generate answer using configured model via Bedrock Converse API
    """
    if event.get('requestContext', {}).get('http', {}).get('method') == 'OPTIONS':
        return build_response(200, {})

    total_start = time.time()

    try:
        body = json.loads(event.get('body', '{}'))
        user_message = body.get('message', '')

        if not user_message:
            return build_response(400, {'error': 'message field is required'})

        # ── Step 1: Retrieve relevant documents ──
        retrieve_start = time.time()
        retrieve_resp = bedrock_agent_runtime.retrieve(
            knowledgeBaseId=KNOWLEDGE_BASE_ID,
            retrievalQuery={'text': user_message},
            retrievalConfiguration={
                'vectorSearchConfiguration': {
                    'numberOfResults': 5
                }
            }
        )
        retrieve_duration = time.time() - retrieve_start

        contexts = []
        sources = []
        for result in retrieve_resp.get('retrievalResults', []):
            text = result.get('content', {}).get('text', '')
            if text:
                contexts.append(text)
                s3_uri = result.get('location', {}).get('s3Location', {}).get('uri', '')
                sources.append({'snippet': text[:200], 'uri': s3_uri})

        context_block = '\n\n---\n\n'.join(contexts) if contexts else 'No relevant documents found.'

        # ── Step 2: Generate answer via Converse API ──
        generate_start = time.time()
        system_prompt = (
            "You are a helpful shopping assistant for Merxly store. "
            "Answer the customer's question based ONLY on the provided context. "
            "If the context does not contain enough information, say so honestly. "
            "Always respond in the same language the customer used."
        )

        user_prompt = f"Context from knowledge base:\n{context_block}\n\nCustomer question: {user_message}"

        converse_resp = bedrock_runtime.converse(
            modelId=MODEL_ID,
            messages=[
                {'role': 'user', 'content': [{'text': user_prompt}]}
            ],
            system=[{'text': system_prompt}],
            inferenceConfig={
                'maxTokens': 2048,
                'temperature': 0.7,
                'topP': 0.9
            }
        )
        generate_duration = time.time() - generate_start

        answer = converse_resp['output']['message']['content'][0]['text']
        total_duration = time.time() - total_start

        # ── CloudWatch Metrics Log ──
        print(json.dumps({
            'event': 'chat_response',
            'question': user_message[:100],
            'retrieve_seconds': round(retrieve_duration, 2),
            'generate_seconds': round(generate_duration, 2),
            'total_seconds': round(total_duration, 2),
            'model_id': MODEL_ID,
            'sources_count': len(sources),
            'answer_length': len(answer)
        }))

        return build_response(200, {
            'answer': answer,
            'sources': sources,
            'timing': {
                'retrieve_seconds': round(retrieve_duration, 2),
                'generate_seconds': round(generate_duration, 2),
                'total_seconds': round(total_duration, 2)
            }
        })

    except Exception as e:
        total_duration = time.time() - total_start
        print(json.dumps({
            'event': 'chat_error',
            'error': str(e),
            'total_seconds': round(total_duration, 2)
        }))
        import traceback
        traceback.print_exc()
        return build_response(500, {'error': f'Internal server error: {str(e)}'})


def build_response(status_code, body):
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': ALLOWED_ORIGIN,
            'Access-Control-Allow-Headers': 'Content-Type,Authorization',
            'Access-Control-Allow-Methods': 'POST,OPTIONS'
        },
        'body': json.dumps(body, ensure_ascii=False)
    }
