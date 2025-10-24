class AllLocalizations {
  AllLocalizations();

  static final Map<String, Map<String, String>> localizedStrings = {
    'en': {
      //home page
      "add_words": "Add Words",
      "upload_video": "Upload Video",
      "view_stats": "View Stats",
      "hello": "Hello!",
      "home_page": "Home Page",
      "word_buds": "WordBuds",
      "knows": "knows",
      "words": "words",
      "most_recent": "Most recent word is:",
      "words_in_past_week": "Words learned in the past week:",
      "choose_file": "Choose File",

      //profile
      "profile": "User Profile",
      "sign_out": "Sign Out",
      "delete_account": "Delete Account",

      //admin page
      "admin_page": "Admin Page",
      "selected_user_id": "Selected User ID",
      "User Roles": "User Roles",
      "get_custom_claims": "Get Custom Claims",
      "assign_parent_role": "Assign Parent Role",
      "remove_parent_role": "Remove Parent Role",
      "assign_researcher_role": "Assign Researcher Role",
      "remove_researcher_role": "Remove Researcher Role",
      "assign_admin_role": "Assign Admin Role",
      "remove_admin_role": "Remove Admin Role",
      "get_email-uid_data": "Get Email-UID Data",
      "roles": "Roles",
      "user_is_disabled": "User is Disabled",

      //add words
      "child_said": "My Child Said...",
      "enter_text": "Enter word or sentence",
      "submit": "submit",
      "success": "Success!",
      "word_success": "Words successfully submitted!",
      "error": "Error!",
      "words_error": " not found in dictionary, please try again!",
      "go_to_settings": "Navigate to settings to add a child",
      "entry_mode_label": "Entry mode",
      "word_mode": "Word",
      "phrase_mode": "Phrase",
      "word_input_label": "Add a word",
      "word_input_hint": "Type the word your child said",
      "phrase_input_label": "Add a phrase",
      "phrase_input_hint": "Type the phrase your child said",
      "note_optional": "Note (optional)",
      "note_hint": "Add context about the moment",
      "video_optional": "Attach video (optional)",
      "processing_state": "Processing…",
      "video_not_ready_message":
          "We couldn't store the video yet. Please try again once your profile finishes loading.",
      "word_processing_queued": 'Queued "{word}" for enrichment.',
      "word_already_processed": '"{word}" is already enriched.',
      "phrase_processing_queued":
          "Queued {count} new words from this phrase.",
      "phrase_already_processed": "Phrase words already enriched.",
      "words_processing_summary":
          "Queued {count} word(s) for enrichment.",
      "words_already_processed":
          "All selected words are already enriched.",

      //stats page
      "learning_summary": "Learning Summary",
      "num_days": "Over how many days...",
      "words_per_day": "New Words Per Day",
      "select_graph": "Select Graph Type",
      "words_per_pos": "All Words Per Part of Speech",
      "loading": "Loading...",
      "No-Children-nl-Yet": "No Children\nYet",
      "over_num_days": "Over how many days...",
      "select_option": "select an option",
      "Words Learned / Day": "Words Learned / Day",
      "All Words / Part of Speech": "All Words / Part of Speech",
      "New Words Per Day": "New Words Per Day",
      "Total Number of Words by Part of Speech":
          "Total Number of Words by Part of Speech",

      //settings
      "settings": "Settings",
      "parent_settings": "Parent Settings",
      "add_child": "Add Child",
      "choose_name": "Choose Name...",
      "select_language": "Language",
      "choose_birthday": "Tap to choose birthday...",
      "child_added": "Child Added!",
      "add_child_success": "Child Added!",
      "child_not_added": "Failed to Add Child",
      "add_child_failed": "Failed to add your child, please try again.",
      "invalid_type": "Invalid Type",
      "access_child": "access to your child",
      "grant_permission": "Are you sure you want to give parent with email",
      "No": "No",
      "Yes": "Yes",

      //sign in
      "welcome_sign_in": "Welcome to BabyWordsTracker, please sign in!",
      "welcome_sign_up": "Welcome to BabyWordsTracker, please sign up!",
      "terms_and_conditions":
          "By signing in, you agree to our terms and conditions.",
      "child_to_new_parent": "Give Another Parent Access To Current Child:",
      "choose_email": "Choose Email...",
      "no_email": "Please give some input for the email field.",

      //top bar
      "curr_child": "Current child: ",
      "select_child": "Select Child",
    },
    'es': {
      "add_words": "Añadir Palabras",
      "upload_video": "Subir Video",
      "view_stats": "Ver Estadísticas",
      "hello": "Hola!",
      "home_page": "Página Principal",
      "word_buds": "WordBuds",
      "profile": "Perfil de Usuario",
      "sign_out": "Cerrar Sesión",
      "delete_account": "Eliminar Cuenta",
      "child_said": "Mi Hijo Dijo...",
      "enter_text": "Escriba una palabra o frase",
      "choose_file": "Elegir Archivo",
      "submit": "enviar",
      "learning_summary": "Resumen de Aprendizaje",
      "num_days": "¿Durante cuántos días?",
      "words_per_day": "Nuevas Palabras por Día",
      "select_graph": "Seleccionar Tipo de Gráfica",
      "words_per_pos": "Todas las Palabras por Parte del Habla",
      "success": "¡Éxito!",
      "word_success": "¡Palabras enviadas con éxito!",
      "error": "¡Error!",
      "words_error":
          " no se encontraron en el diccionario, ¡por favor inténtalo de nuevo!",
      "loading": "Cargando...",
      "No-Children-nl-Yet": "Aún No Hay\nNiños",
      "settings": "Configuración",
      "parent_settings": "Configuración Para Padres",
      "add_child": "Agregar hijo",
      "choose_name": "Elegir nombre...",
      "choose_birthday": "Toca para elegir la fecha de cumpleaños...",
      "select_language": "Idioma",
      "child_added": "¡Hijo agregado!",
      "add_child_success": "¡Hijo agregado!",
      "child_not_added": "No se pudo agregar al hijo",
      "add_child_failed":
          "No se pudo agregar a su hijo, por favor intente de nuevo.",
      "invalid_type": "Tipo inválido",
      "access_child": "acceso a tu hijo",
      "grant_permission":
          "¿Estás seguro de que deseas dar acceso al padre con el correo electrónico",
      "No": "No",
      "Yes": "Si",
      "entry_mode_label": "Modo de entrada",
      "word_mode": "Palabra",
      "phrase_mode": "Frase",
      "word_input_label": "Agregar una palabra",
      "word_input_hint": "Escriba la palabra que dijo su hijo",
      "phrase_input_label": "Agregar una frase",
      "phrase_input_hint": "Escriba la frase que dijo su hijo",
      "note_optional": "Nota (opcional)",
      "note_hint": "Agregue contexto sobre el momento",
      "video_optional": "Adjuntar video (opcional)",
      "processing_state": "Procesando...",
      "video_not_ready_message":
          "Aún no pudimos guardar el video. Vuelve a intentarlo cuando se complete la carga de tu perfil.",
      "word_processing_queued":
          'Se agregó "{word}" para enriquecimiento.',
      "word_already_processed": '"{word}" ya está enriquecida.',
      "phrase_processing_queued":
          "Se agregaron {count} palabras nuevas de esta frase.",
      "phrase_already_processed": "Las palabras de la frase ya están enriquecidas.",
      "words_processing_summary":
          "Se agregaron {count} palabra(s) para enriquecimiento.",
      "words_already_processed":
          "Las palabras seleccionadas ya están enriquecidas.",
      "welcome_sign_in":
          "¡Bienvenido a BabyWordsTracker, por favor inicia sesión!",
      "welcome_sign_up":
          "¡Bienvenido a BabyWordsTracker, por favor regístrate!",
      "terms_and_conditions":
          "Al iniciar sesión, aceptas nuestros términos y condiciones.",
      "over_num_days": "¿Durante cuántos días...",
      "select_option": "selecciona una opción",
      "Words Learned / Day": "Palabras aprendidas / Día",
      "All Words / Part of Speech": "Todas las palabras / Parte de la oración",
      "New Words Per Day": "Nuevas palabras por día",
      "Total Number of Words by Part of Speech":
          "Número total de palabras por parte de la oración",
      "child_to_new_parent": "Dar acceso a otro padre para el hijo actual:",
      "choose_email": "Elegir correo electrónico...",
      "no_email":
          "Por favor, ingrese un valor en el campo de correo electrónico.",
      "knows": "sabe",
      "words": "palabras",
      "most_recent": "La palabra más reciente es:",
      "words_in_past_week": "Palabras aprendidas la semana pasada:",
      "go_to_settings": "Vaya a la configuración para agregar un niño",
      "curr_child": "Niño actual: ",
      "select_child": "Seleccionar niño",

      //admin page
      "admin_page": "Pagina de Administrador",
      "selected_user_id": "ID de Usuario Seleccionado",
      "User Roles": "Roles de Usuario",
      "get_custom_claims": "Obtener Reclamaciones Personalizadas",
      "assign_parent_role": "Asignar Rol de Padre",
      "remove_parent_role": "Eliminar Rol de Padre",
      "assign_researcher_role": "Asignar Rol de Investigador",
      "remove_researcher_role": "Eliminar Rol de Investigador",
      "assign_admin_role": "Asignar Rol de Administrador",
      "remove_admin_role": "Eliminar Rol de Administrador",
      "get_email-uid_data": "Obtener Datos de Correo Electrónico-UID",
      "roles": "Roles",
      "user_is_disabled": "Usuario Deshabilitado",
    }
  };
}
