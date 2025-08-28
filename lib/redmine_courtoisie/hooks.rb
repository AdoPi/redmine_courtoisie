module RedmineCourtoisie
  
  class ViewHooks < Redmine::Hook::ViewListener
    render_on :view_issues_form_details_bottom, partial: 'courtoisie/generate_button'
    
    def view_layouts_base_html_head(context)
      javascript_include_tag('move_gen_button', plugin: 'redmine_courtoisie')
    end
    
  end
  
  class Hooks < Redmine::Hook::Listener
    require 'net/http'
    require 'json'
    
    def controller_issues_new_before_save(context={})
      begin
        
        params = context[:params]
        return if params[:courtoisie_generate].to_s != '1'
        
        issue = context[:issue]
        user_id = issue.author_id
        
        members = (Setting.plugin_redmine_courtoisie['members_to_courtesy'] || '')
        .split(',')
        .map(&:strip)
        .map(&:to_i) 
        
        if members.include?(user_id)
          api_key = Setting.plugin_redmine_courtoisie['gemini_api_key']
          model = Setting.plugin_redmine_courtoisie['model']
          
          title = issue.subject.to_s
          description = issue.description.to_s
          combined = "TITLE:\n#{title}\n\nDESCRIPTION:\n#{description}"
          
          max_chars = Setting.plugin_redmine_courtoisie['max_chars'] || 3000
          if combined.length > max_chars
            return
          end
          
          prompt = <<~PROMPT
        Tu es un assistant qui reformule et corrige.
        Reçois ci-dessous un titre et une description d'issue Redmine.
        1) Corrige les fautes et rends le TITRE clair, concis, et sans majuscules inutiles.
        2) Réécris la DESCRIPTION pour qu'elle soit polie et courtoise, tout en conservant le sens. Tu peux commencer par Hello, mettre des svp où c'est nécessaire, pas besoin d'être trop formel non plus.
        3) Répond strictement en JSON (sans autre texte) avec deux champs : "title" et "description".
           Exemple de sortie attendue :
           {
             "title": "Titre corrigé ici",
             "description": "Texte courtois ici..."
           }
        INPUT:
        #{combined}
      PROMPT
          
          
          uri = URI.parse("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent")
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          req = Net::HTTP::Post.new(uri.request_uri, { 'Content-Type' => 'application/json', 'X-goog-api-key' => "#{api_key}" })
          Rails.logger.error "[redmine_courtoisie] Gemini API Request: HTTP #{api_key}"
          
          body = {
            contents: [
              { parts: [ { text: prompt } ] }
            ]
          }
          
          req.body = body.to_json
          resp = http.request(req)
          
          Rails.logger.info "[redmine_courtoisie] Response: #{resp}"
          
          if resp.code.to_i >= 400
            Rails.logger.error "[redmine_courtoisie] Gemini API error: HTTP #{resp.code} - #{resp.body}"
            return
          end
          
          parsed = JSON.parse(resp.body) rescue nil
          
          unless parsed && parsed['candidates'] && parsed['candidates'][0]['content']['parts'][0]['text']
            Rails.logger.error "[redmine_courtoisie] Unexpected Gemini response: #{resp.body}"
            return
          end
          
          
          raw = parsed['candidates'][0]['content']['parts'][0]['text']
          json_text = extract_json(raw)
          data = JSON.parse(json_text)
          return unless data && data['title'] && data['description']
          
          issue.subject = data['title']
          issue.description = data['description']
          
          
        end
      rescue => e
        Rails.logger.error "[redmine_courtoisie] Gemini exception: #{e.class}: #{e.message}"
      end
    end
    
    
    def extract_json(text)
      return nil unless text.is_a?(String)
      stripped = text.strip
      return stripped if stripped.start_with?('{') && stripped.end_with?('}')
      first = text.index('{')
      last = text.rindex('}')
      if first && last && last > first
        candidate = text[first..last]
        begin
          JSON.parse(candidate)
          return candidate
        rescue
        end
      end
      nil
    end
    
  end
end

