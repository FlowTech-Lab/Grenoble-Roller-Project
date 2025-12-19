// Test JavaScript pour vérifier le comportement du bouton submit avec l'essai gratuit
// À exécuter dans la console du navigateur ou avec un framework de test JS

describe('Registration Form - Free Trial Button Toggle', function() {
  beforeEach(function() {
    // Simuler un formulaire avec checkbox essai gratuit
    document.body.innerHTML = `
      <form id="attendForm_show_initiation">
        <input type="checkbox" id="use_free_trial_show_initiation" />
        <button type="submit" id="submitBtn_show_initiation">Confirmer l'inscription</button>
      </form>
    `;
  });

  it('should disable button when checkbox is unchecked', function() {
    const checkbox = document.getElementById('use_free_trial_show_initiation');
    const button = document.getElementById('submitBtn_show_initiation');
    
    checkbox.checked = false;
    if (window.toggleSubmitButton_show_initiation) {
      window.toggleSubmitButton_show_initiation();
    }
    
    expect(button.disabled).toBe(true);
  });

  it('should enable button when checkbox is checked', function() {
    const checkbox = document.getElementById('use_free_trial_show_initiation');
    const button = document.getElementById('submitBtn_show_initiation');
    
    checkbox.checked = true;
    if (window.toggleSubmitButton_show_initiation) {
      window.toggleSubmitButton_show_initiation();
    }
    
    expect(button.disabled).toBe(false);
  });
});
