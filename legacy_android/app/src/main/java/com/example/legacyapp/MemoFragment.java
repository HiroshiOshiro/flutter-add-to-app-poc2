package com.example.legacyapp;

import android.content.Intent;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterEngineCache;
import io.flutter.embedding.engine.FlutterEngineGroup;
import io.flutter.embedding.engine.dart.DartExecutor;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.EditText;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

public class MemoFragment extends Fragment {

    private static final String PREFS_NAME = "legacy_app_prefs";
    private static final String KEY_NAME = "draft_name";
    private static final String KEY_EMAIL = "draft_email";
    private static final String KEY_MESSAGE = "draft_message";

    private EditText nameEdit;
    private EditText emailEdit;
    private EditText messageEdit;
    private SharedPreferences prefs;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_memo, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        prefs = requireContext().getSharedPreferences(PREFS_NAME, android.content.Context.MODE_PRIVATE);

        nameEdit = view.findViewById(R.id.editName);
        emailEdit = view.findViewById(R.id.editEmail);
        messageEdit = view.findViewById(R.id.editMessage);

        loadDraft();

        TextWatcher draftSaver = new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {
            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                saveDraft();
            }

            @Override
            public void afterTextChanged(Editable s) {
            }
        };
        nameEdit.addTextChangedListener(draftSaver);
        emailEdit.addTextChangedListener(draftSaver);
        messageEdit.addTextChangedListener(draftSaver);

        view.findViewById(R.id.buttonNext).setOnClickListener(v -> {
            BaseActivity.sFormData.name = nameEdit.getText().toString();
            BaseActivity.sFormData.email = emailEdit.getText().toString();
            BaseActivity.sFormData.message = messageEdit.getText().toString();
            startActivity(newFlutterConfirmIntent());
        });
    }

    @Override
    public void onResume() {
        super.onResume();
        // Re-read the draft whenever this tab becomes visible again, e.g.
        // after coming back from Complete.
        if (nameEdit != null) {
            loadDraft();
        }
    }

    private void loadDraft() {
        nameEdit.setText(prefs.getString(KEY_NAME, ""));
        emailEdit.setText(prefs.getString(KEY_EMAIL, ""));
        messageEdit.setText(prefs.getString(KEY_MESSAGE, ""));
    }

    private void saveDraft() {
        prefs.edit()
                .putString(KEY_NAME, nameEdit.getText().toString())
                .putString(KEY_EMAIL, emailEdit.getText().toString())
                .putString(KEY_MESSAGE, messageEdit.getText().toString())
                .apply();
    }

    // ガイド「6. ステップ3」は FlutterEngineGroup を既定として推奨しているが、
    // その起動コードのスニペットが載っていないため、公式APIから自分で書いた。
    private static final String FLUTTER_ENGINE_ID = "legacyapp_engine";

    private Intent newFlutterConfirmIntent() {
        FlutterEngineGroup group = new FlutterEngineGroup(requireContext());
        FlutterEngine engine = group.createAndRunEngine(
                requireContext(),
                DartExecutor.DartEntrypoint.createDefault(),
                "/confirm");
        FlutterEngineCache.getInstance().put(FLUTTER_ENGINE_ID, engine);
        return FlutterActivity.withCachedEngine(FLUTTER_ENGINE_ID).build(requireContext());
    }
}
